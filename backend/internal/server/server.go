package server

import (
	"crypto/subtle"
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"github.com/scamshield/backend/internal/applink"
	"github.com/scamshield/backend/internal/detect"
)

type Server struct {
	router *Router
	fb     detect.Fallback

	// Subscription notifications (optional; see WithSubscriptions).
	subs     *Subscribers
	appID    string
	password string
}

func New(router *Router, fb detect.Fallback) *Server { return &Server{router: router, fb: fb} }

// WithSubscriptions lets /subscription/notify keep subs in sync. AppLink sends
// our applicationId and password in the body; if appID/password are set, a
// notification that doesn't match them is ignored.
func (s *Server) WithSubscriptions(subs *Subscribers, appID, password string) *Server {
	s.subs, s.appID, s.password = subs, appID, password
	return s
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })
	mux.HandleFunc("POST /scan/check", s.scanCheck)
	mux.HandleFunc("POST /sms/receive", s.smsReceive)
	mux.HandleFunc("POST /ussd/receive", s.ussdReceive)
	mux.HandleFunc("POST /subscription/notify", s.subscriptionNotify)
	mux.HandleFunc("POST /sms/report", s.ack)
	mux.HandleFunc("POST /caas/notify", s.ack)
	return mux
}

// scanCheck is what the Flutter app calls.
func (s *Server) scanCheck(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Message string `json:"message"`
		Sender  string `json:"sender"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<16)).Decode(&in); err != nil || in.Message == "" {
		http.Error(w, "message required", http.StatusBadRequest)
		return
	}
	writeJSON(w, detect.AnalyzeWithFallback(r.Context(), s.fb, in.Message, in.Sender))
}

// smsReceive is the AppLink MO webhook. AppLink checks statusCode in the body
// (not just HTTP 200), so we answer S1000 once accepted and work asynchronously.
func (s *Server) smsReceive(w http.ResponseWriter, r *http.Request) {
	var in applink.Inbound
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<16)).Decode(&in); err != nil {
		writeJSON(w, map[string]string{"statusCode": "E1312", "statusDetail": "bad request"})
		return
	}
	// Key users by the raw sourceAddress: with number masking ON it is not a
	// phone number, and converting it (as before) silently dropped every message.
	if from := strings.TrimSpace(in.SourceAddress); from != "" {
		s.router.Route(from, in.Message)
	}
	writeJSON(w, map[string]string{"statusCode": "S1000", "statusDetail": "Success"})
}

// subscriptionNotify is called by AppLink when a subscription changes
// (e.g. "unreg scam", renewal, payment failure). The body contains our app
// password, so it is never logged.
func (s *Server) subscriptionNotify(w http.ResponseWriter, r *http.Request) {
	var in struct {
		ApplicationID      string `json:"applicationId"`
		Password           string `json:"password"`
		SubscriberID       string `json:"subscriberId"`
		Status             string `json:"status"`
		SubscriptionStatus string `json:"subscriptionStatus"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<16)).Decode(&in); err != nil {
		writeJSON(w, map[string]string{"statusCode": "E1312", "statusDetail": "bad request"})
		return
	}
	status := in.Status
	if status == "" {
		status = in.SubscriptionStatus
	}
	user := strings.TrimSpace(in.SubscriberID)

	switch {
	case s.subs == nil || user == "":
		// nothing to update
	case !s.trusted(in.ApplicationID, in.Password):
		log.Printf("subscription/notify: ignored (applicationId/password mismatch)")
	case applink.Active(status):
		s.subs.Add(user)
		log.Printf("subscription/notify: active (%s)", strings.ToUpper(status))
	default:
		// UNREGISTERED, BLOCKED, TEMPORARY_BLOCKED, ...: paid extras off.
		s.subs.Remove(user)
		log.Printf("subscription/notify: inactive (%s)", strings.ToUpper(status))
	}
	writeJSON(w, map[string]string{"statusCode": "S1000", "statusDetail": "Success"})
}

func (s *Server) trusted(appID, password string) bool {
	if s.appID != "" && appID != s.appID {
		return false
	}
	if s.password != "" && subtle.ConstantTimeCompare([]byte(password), []byte(s.password)) != 1 {
		return false
	}
	return true
}

// ack answers AppLink callbacks we don't act on yet (delivery reports, CaaS).
func (s *Server) ack(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, map[string]string{"statusCode": "S1000", "statusDetail": "Success"})
}

// ussdReceive is a placeholder: USSD is blocked until AppLink assigns a keyword.
func (s *Server) ussdReceive(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, map[string]string{"statusCode": "S1000", "statusDetail": "Success"})
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(v)
}
