package applink

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

// fakeApplink answers like Applink: always HTTP 200, result in statusCode.
func fakeApplink(t *testing.T, replies map[string]string) *httptest.Server {
	t.Helper()
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body map[string]any
		_ = json.NewDecoder(r.Body).Decode(&body)
		if body["applicationId"] != "APP_TEST" || body["password"] != "secret" {
			t.Errorf("%s: credentials missing from body", r.URL.Path)
		}
		reply, ok := replies[r.URL.Path]
		if !ok {
			t.Fatalf("unexpected call to %s", r.URL.Path)
		}
		w.Write([]byte(reply))
	}))
}

func testClient(base string) *Client {
	return New(Config{
		AppID: "APP_TEST", Password: "secret",
		OTPRequestURL:   base + "/otp/request",
		OTPVerifyURL:    base + "/otp/verify",
		SubscriptionURL: base + "/subscription/send",
		ChargingInfoURL: base + "/subscription/getSubscriberChargingInfo",
	})
}

func TestOTPSignUpFlow(t *testing.T) {
	srv := fakeApplink(t, map[string]string{
		"/otp/request": `{"statusCode":"S1000","referenceNo":"REF123","statusDetail":"Success"}`,
		"/otp/verify":  `{"statusCode":"S1000","subscriptionStatus":"REGISTERED","subscriberId":"tel:B%3C4maskedid"}`,
	})
	defer srv.Close()
	c := testClient(srv.URL)
	ctx := context.Background()

	ref, err := c.RequestOTP(ctx, "tel:8801912345678")
	if err != nil || ref != "REF123" {
		t.Fatalf("RequestOTP = %q, %v", ref, err)
	}
	res, err := c.VerifyOTP(ctx, ref, " 123456 ")
	if err != nil {
		t.Fatal(err)
	}
	if res.SubscriberID != "tel:B%3C4maskedid" { // masked id kept exactly
		t.Errorf("subscriberId = %q", res.SubscriberID)
	}
	if !Active(res.Status) {
		t.Errorf("status %q should be active", res.Status)
	}
}

func TestWrongOTPIsReportedNotSuccess(t *testing.T) {
	// HTTP 200, but an error in the body: must NOT count as success.
	srv := fakeApplink(t, map[string]string{
		"/otp/verify": `{"statusCode":"E1850","statusDetail":"Invalid OTP"}`,
	})
	defer srv.Close()
	_, err := testClient(srv.URL).VerifyOTP(context.Background(), "REF123", "000000")
	if !IsCode(err, CodeWrongOTP) {
		t.Fatalf("want E1850, got %v", err)
	}
}

func TestSubscriptionStatusWithTrailingDot(t *testing.T) {
	srv := fakeApplink(t, map[string]string{
		"/subscription/send": `{"statusCode":"S1000","statusDetail":"not registered","subscriptionStatus":"UNREGISTERED."}`,
	})
	defer srv.Close()
	if err := testClient(srv.URL).Unsubscribe(context.Background(), "tel:8801912345678"); err != nil {
		t.Fatalf("UNREGISTERED. should be success: %v", err)
	}
}

func TestPendingIsNotActive(t *testing.T) {
	for _, s := range []string{"REG_PENDING", "INITIAL", "UNREGISTERED", ""} {
		if Active(s) {
			t.Errorf("%q must not unlock paid features", s)
		}
	}
	for _, s := range []string{"REGISTERED", "REGISTERED.", " trial "} {
		if !Active(s) {
			t.Errorf("%q should be active", s)
		}
	}
}

// TestAgainstMock runs only when the Applink mock server is running:
//
//	APPLINK_MOCK=http://127.0.0.1:8089 go test ./internal/applink -run Mock -v
func TestAgainstMock(t *testing.T) {
	base := os.Getenv("APPLINK_MOCK")
	if base == "" {
		t.Skip("set APPLINK_MOCK=http://127.0.0.1:8089 with the mock running")
	}
	c := testClient(base)
	ctx := context.Background()

	ref, err := c.RequestOTP(ctx, "tel:8801812345678")
	if err != nil {
		t.Fatalf("RequestOTP: %v", err)
	}
	res, err := c.VerifyOTP(ctx, ref, "123564")
	if err != nil {
		t.Fatalf("VerifyOTP: %v", err)
	}
	t.Logf("subscribed %s (%s)", res.SubscriberID, res.Status)

	if st, err := c.Subscribe(ctx, res.SubscriberID); err != nil || !Active(st) {
		t.Fatalf("Subscribe = %q, %v", st, err)
	}
	info, err := c.GetChargingInfo(ctx, res.SubscriberID)
	if err != nil || len(info) == 0 {
		t.Fatalf("GetChargingInfo = %v, %v", info, err)
	}
	if err := c.Unsubscribe(ctx, res.SubscriberID); err != nil {
		t.Fatalf("Unsubscribe: %v", err)
	}
	// Error path: the mock's /fail-E1850/ prefix returns that code.
	bad := testClient(base + "/fail-E1850")
	if _, err := bad.VerifyOTP(ctx, ref, "000000"); !IsCode(err, CodeWrongOTP) {
		t.Fatalf("want E1850 from mock, got %v", err)
	}
}
