package server

import (
	"context"
	"log"
	"sync"
	"time"

	"github.com/scamshield/backend/internal/applink"
)

// OTPClient is the part of *applink.Client the sign-up flow needs; faked in tests.
type OTPClient interface {
	RequestOTP(ctx context.Context, subscriberID string) (string, error)
	VerifyOTP(ctx context.Context, referenceNo, otp string) (applink.VerifyResult, error)
}

const otpTTL = 5 * time.Minute // AppLink OTPs expire quickly; keep refs short-lived

// Sign-up replies (Banglish, one SMS part each). The OTP line follows the rule
// from our own lessons: only the user types the code, nobody calls for it.
const (
	msgOTPSent     = "OTP pathano holo. Code ta reply korun: scam <code> (5 min). ScamShield kokhono call kore code chaibe na."
	msgSubscribed  = "Shagotom! Family Guard chalu (Tk 30/mash). Bondho korte likhun: unreg scam"
	msgPending     = "Apnar request processing hocche. Kichu khon por abar check korun."
	msgWrongCode   = "Code ta thik na. Abar likhun: scam <code>"
	msgCodeExpired = "Code er meyad shesh. Notun code er jonno likhun: scam join"
	msgTryLater    = "Ekhon sign-up kora jacche na. Kichu khon por abar likhun: scam join"
)

type otpWait struct {
	ref string
	at  time.Time
}

// Signup runs "scam join" -> OTP SMS from AppLink -> "scam <code>" -> subscribed.
// State lives in memory: a restart only means the user sends "scam join" again.
type Signup struct {
	otp  OTPClient
	send Sender

	mu      sync.Mutex
	waiting map[string]otpWait // user (raw sourceAddress) -> OTP reference
	now     func() time.Time
}

func NewSignup(otp OTPClient, send Sender) *Signup {
	return &Signup{otp: otp, send: send, waiting: map[string]otpWait{}, now: time.Now}
}

// Waiting reports whether user has an unexpired OTP request.
func (s *Signup) Waiting(user string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	w, ok := s.waiting[user]
	if ok && s.now().Sub(w.at) > otpTTL {
		delete(s.waiting, user)
		return false
	}
	return ok
}

// Start asks AppLink to text the user an OTP. The referenceNo stays here on
// the server; it is never sent to the user.
func (s *Signup) Start(ctx context.Context, user string) {
	ref, err := s.otp.RequestOTP(ctx, user)
	if err != nil {
		log.Printf("signup: OTP request failed: %v", err)
		s.reply(ctx, user, msgTryLater)
		return
	}
	s.mu.Lock()
	s.waiting[user] = otpWait{ref: ref, at: s.now()}
	s.mu.Unlock()
	s.reply(ctx, user, msgOTPSent)
}

// Verify checks the code the user replied with.
func (s *Signup) Verify(ctx context.Context, user, code string) {
	s.mu.Lock()
	w, ok := s.waiting[user]
	s.mu.Unlock()
	if !ok {
		s.reply(ctx, user, msgCodeExpired)
		return
	}

	res, err := s.otp.VerifyOTP(ctx, w.ref, code)
	switch {
	case applink.IsCode(err, applink.CodeWrongOTP):
		s.reply(ctx, user, msgWrongCode) // keep waiting: same referenceNo
		return
	case applink.IsCode(err, applink.CodeExpiredOTP):
		s.forget(user)
		s.reply(ctx, user, msgCodeExpired)
		return
	case err != nil:
		log.Printf("signup: OTP verify failed: %v", err)
		s.forget(user)
		s.reply(ctx, user, msgTryLater)
		return
	}

	s.forget(user)
	// TODO(next PR): store res.SubscriberID + status so paid features can
	// check access, and keep it in sync with /subscription/notify.
	if applink.Active(res.Status) {
		s.reply(ctx, user, msgSubscribed)
	} else {
		s.reply(ctx, user, msgPending) // e.g. REG_PENDING: wait for the notification
	}
}

func (s *Signup) forget(user string) {
	s.mu.Lock()
	delete(s.waiting, user)
	s.mu.Unlock()
}

func (s *Signup) reply(ctx context.Context, to, text string) {
	if err := s.send.SendSMS(ctx, to, text); err != nil {
		log.Printf("signup: send failed: %v", err)
	}
}
