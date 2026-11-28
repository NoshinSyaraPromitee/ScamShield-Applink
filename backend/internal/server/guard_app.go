package server

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
)

// App-facing Family Guard: the Flutter app acts as the guardian (child). The
// parent still generates the code over SMS ("scam guard"). The app is keyed by
// the X-Device-Id header (demo: no accounts).

func (g *Guard) isGuardian(user string) bool {
	g.mu.Lock()
	defer g.mu.Unlock()
	for _, list := range g.guardians {
		if contains(list, user) {
			return true
		}
	}
	return false
}

// PairApp pairs an app user as guardian using a parent's code. It returns a
// short error key ("bad_code", "self", "need_plan", "full") or "" on success.
func (g *Guard) PairApp(ctx context.Context, user, code string) string {
	g.mu.Lock()
	c, ok := g.codes[code]
	if !ok && g.DemoCode != "" && code == g.DemoCode {
		c, ok = guardCode{parent: "demo:parent", at: g.now()}, true
	}
	if ok && g.now().Sub(c.at) > guardCodeTTL {
		delete(g.codes, code)
		ok = false
	}
	g.mu.Unlock()
	switch {
	case !ok:
		return "bad_code"
	case c.parent == user:
		return "self"
	case g.isSubscribed != nil && !g.isSubscribed(user):
		return "need_plan"
	}
	g.mu.Lock()
	list := g.guardians[c.parent]
	if !contains(list, user) {
		if len(list) >= maxGuardians {
			g.mu.Unlock()
			return "full"
		}
		g.guardians[c.parent] = append(list, user)
	}
	delete(g.codes, code)
	g.mu.Unlock()
	if !strings.HasPrefix(c.parent, "demo:") {
		g.reply(ctx, c.parent, msgGuardPaired) // tell the parent by SMS
	}
	return ""
}

func deviceID(r *http.Request) string {
	if d := strings.TrimSpace(r.Header.Get("X-Device-Id")); d != "" {
		return "app:" + d
	}
	return "app:demo"
}

func (s *Server) familyStatus(w http.ResponseWriter, r *http.Request) {
	paired := s.guard != nil && s.guard.isGuardian(deviceID(r))
	writeJSON(w, map[string]any{"paired": paired})
}

func (s *Server) familyPair(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Code string `json:"code"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<10)).Decode(&in); err != nil || s.guard == nil {
		http.Error(w, "code required", http.StatusBadRequest)
		return
	}
	if errKey := s.guard.PairApp(r.Context(), deviceID(r), strings.TrimSpace(in.Code)); errKey != "" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": errKey})
		return
	}
	writeJSON(w, map[string]any{"paired": true})
}
