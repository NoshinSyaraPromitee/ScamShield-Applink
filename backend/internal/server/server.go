package server

import (
	"encoding/json"
	"net/http"

	"github.com/scamshield/backend/internal/applink"
	"github.com/scamshield/backend/internal/detect"
)

type Server struct {
	fwd *Forwarder
	fb  detect.Fallback
}

func New(fwd *Forwarder, fb detect.Fallback) *Server { return &Server{fwd: fwd, fb: fb} }

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })
	mux.HandleFunc("POST /scan/check", s.scanCheck)
	mux.HandleFunc("POST /sms/receive", s.smsReceive)
	mux.HandleFunc("POST /ussd/receive", s.ussdReceive)
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
	if from := detect.NormalizeNumber(in.SourceAddress); from != "" {
		s.fwd.Receive(from, in.Message)
	}
	writeJSON(w, map[string]string{"statusCode": "S1000", "statusDetail": "Success"})
}

// ussdReceive is a placeholder; the session handler is Maha's task.
func (s *Server) ussdReceive(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, map[string]string{"statusCode": "S1000", "statusDetail": "Success"})
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(v)
}
