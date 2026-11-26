package server

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/scamshield/backend/internal/applink"
)

// masked is what AppLink sends when number masking is ON.
const masked = "tel:B%3C4oXdDXcmasked"

type fakeOTP struct {
	requested []string
	verifyErr error
	status    string
}

func (f *fakeOTP) RequestOTP(_ context.Context, sub string) (string, error) {
	f.requested = append(f.requested, sub)
	return "REF1", nil
}

func (f *fakeOTP) VerifyOTP(_ context.Context, ref, otp string) (applink.VerifyResult, error) {
	if f.verifyErr != nil {
		return applink.VerifyResult{}, f.verifyErr
	}
	return applink.VerifyResult{SubscriberID: masked, Status: f.status}, nil
}

// newRouter returns a router that runs commands synchronously.
func newRouter(t *testing.T) (*Router, *fakeSender, *fakeOTP) {
	t.Helper()
	s := &fakeSender{}
	otp := &fakeOTP{status: "REGISTERED"}
	r := NewRouter(s, newFwd(s), NewSignup(otp, s))
	r.run = func(f func(ctx context.Context)) { f(context.Background()) }
	return r, s, otp
}

func TestJoinThenCodeSubscribes(t *testing.T) {
	r, s, otp := newRouter(t)
	r.Route(masked, "SCAM join")
	if len(otp.requested) != 1 || otp.requested[0] != masked {
		t.Fatalf("OTP must be requested for the raw masked address, got %v", otp.requested)
	}
	if !strings.HasPrefix(s.last(), masked+"|OTP pathano holo") {
		t.Fatalf("reply must go to the masked address, got %q", s.last())
	}
	r.Route(masked, "scam 482913")
	if !strings.Contains(s.last(), "Shagotom") {
		t.Fatalf("expected subscribed reply, got %q", s.last())
	}
	if r.signup.Waiting(masked) {
		t.Fatal("sign-up state should be cleared after success")
	}
}

func TestWrongCodeKeepsWaiting(t *testing.T) {
	r, s, otp := newRouter(t)
	r.Route(masked, "scam join")
	otp.verifyErr = &applink.APIError{Code: applink.CodeWrongOTP}
	r.Route(masked, "scam 000000")
	if !strings.Contains(s.last(), "Code ta thik na") || !r.signup.Waiting(masked) {
		t.Fatalf("wrong code should re-prompt and keep waiting, got %q", s.last())
	}
}

func TestPendingStatusIsNotSubscribed(t *testing.T) {
	r, s, otp := newRouter(t)
	otp.status = "REG_PENDING"
	r.Route(masked, "scam join")
	r.Route(masked, "scam 482913")
	if strings.Contains(s.last(), "Shagotom") {
		t.Fatalf("REG_PENDING must not be told they are subscribed: %q", s.last())
	}
}

func TestExpiredWaitGoesToScamCheck(t *testing.T) {
	r, s, _ := newRouter(t)
	r.Route(masked, "scam join")
	r.signup.now = func() time.Time { return time.Now().Add(otpTTL + time.Minute) }
	// No live sign-up any more: digits are not an OTP, so they go to the check.
	r.Route(masked, "scam 482913")
	time.Sleep(100 * time.Millisecond)
	if strings.Contains(s.last(), "Shagotom") {
		t.Fatalf("expired sign-up must not verify, got %q", s.last())
	}
}

func TestDigitsWithoutSignupAreNotOTP(t *testing.T) {
	r, s, otp := newRouter(t)
	r.Route(masked, "scam 123456")
	time.Sleep(100 * time.Millisecond)
	if len(otp.requested) != 0 || strings.Contains(s.last(), "Shagotom") {
		t.Fatalf("digits without a sign-up must not touch OTP, got %v / %q", otp.requested, s.last())
	}
}

func TestHelpAndGuardPlaceholders(t *testing.T) {
	r, s, _ := newRouter(t)
	r.Route(masked, "scam HELP")
	if !strings.Contains(s.last(), "16247") {
		t.Fatalf("help should list hotlines, got %q", s.last())
	}
	r.Route(masked, "scam guard 4821")
	if !strings.Contains(s.last(), "Family Guard") {
		t.Fatalf("guard placeholder expected, got %q", s.last())
	}
}

func TestScamCheckGetsTextWithoutKeywordAndMaskedReply(t *testing.T) {
	r, s, _ := newRouter(t)
	r.Route(masked, "scam 01799999999 Your bKash is blocked, send PIN http://x.xyz")
	time.Sleep(100 * time.Millisecond)
	if !strings.HasPrefix(s.last(), masked+"|SABDHAN") {
		t.Fatalf("expected high-risk verdict to the masked address, got %q", s.last())
	}
}

func TestStripKeyword(t *testing.T) {
	cases := map[string]string{
		"scam join":         "join",
		"  SCAM   help ":    "help",
		"Scam":              "",
		"scammer called me": "scammer called me", // not the keyword
		"join":              "join",              // keyword already removed upstream
	}
	for in, want := range cases {
		if got := stripKeyword(in); got != want {
			t.Errorf("stripKeyword(%q) = %q, want %q", in, got, want)
		}
	}
}

// Before this change, masked numbers were dropped without any reply.
func TestWebhookAcceptsMaskedAddress(t *testing.T) {
	r, s, _ := newRouter(t)
	srv := New(r, nil)
	body := `{"sourceAddress":"` + masked + `","message":"scam help","requestId":"1"}`
	rec := httptest.NewRecorder()
	srv.Handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/sms/receive", bytes.NewBufferString(body)))
	if !strings.Contains(rec.Body.String(), "S1000") {
		t.Fatalf("webhook must answer S1000, got %s", rec.Body.String())
	}
	if !strings.HasPrefix(s.last(), masked+"|") {
		t.Fatalf("masked user got no reply: %v", s.all())
	}
}

func TestDestinationKeepsRawAddress(t *testing.T) {
	if got := applink.Destination(masked); got != masked {
		t.Errorf("masked address changed: %q", got)
	}
	if got := applink.Destination("01711111111"); got != "tel:8801711111111" {
		t.Errorf("local number: %q", got)
	}
}
