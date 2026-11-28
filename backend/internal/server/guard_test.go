package server

import (
	"context"
	"strings"
	"testing"
	"time"
)

const (
	parentAddr = "tel:PARENTmasked"
	childAddr  = "tel:CHILDmasked"
)

func newGuardRouter(t *testing.T, subscribed bool) (*Router, *fakeSender, *Guard) {
	t.Helper()
	r, s, _ := newRouter(t)
	subs := NewSubscribers()
	if subscribed {
		subs.Add(childAddr)
	}
	g := NewGuard(s, subs.Has)
	g.newCode = func() string { return "4821" }
	r.fwd.OnHighRisk = g.Alert
	r.WithGuard(g)
	return r, s, g
}

func sentTo(s *fakeSender, addr string) []string {
	var out []string
	for _, m := range s.all() {
		if strings.HasPrefix(m, addr+"|") {
			out = append(out, strings.TrimPrefix(m, addr+"|"))
		}
	}
	return out
}

func TestGuardPairAndAlert(t *testing.T) {
	r, s, g := newGuardRouter(t, true)
	r.Route(parentAddr, "scam guard")
	if !strings.Contains(s.last(), "scam guard 4821") {
		t.Fatalf("parent should get the code, got %q", s.last())
	}
	r.Route(childAddr, "scam guard 4821")
	if g.Guardians(parentAddr) != 1 {
		t.Fatal("child should be paired")
	}
	if got := sentTo(s, parentAddr); !strings.Contains(got[len(got)-1], "Family Guard chalu") {
		t.Fatalf("parent should be told, got %v", got)
	}
	r.Route(parentAddr, "scam 01799999999 Your bKash is blocked, send PIN now http://x.xyz")
	time.Sleep(150 * time.Millisecond)
	alerts := sentTo(s, childAddr)
	last := alerts[len(alerts)-1]
	if !strings.Contains(last, "high-risk") || strings.Contains(last, "bKash") || strings.Contains(last, "0179") {
		t.Fatalf("child alert must not leak the message, got %q", last)
	}
}

func TestGuardChildMustBeSubscribed(t *testing.T) {
	r, s, g := newGuardRouter(t, false)
	r.Route(parentAddr, "scam guard")
	r.Route(childAddr, "scam guard 4821")
	if g.Guardians(parentAddr) != 0 || !strings.Contains(s.last(), "scam join") {
		t.Fatalf("unsubscribed child must be sent to sign-up, got %q", s.last())
	}
}

func TestGuardBadAndExpiredCode(t *testing.T) {
	r, s, g := newGuardRouter(t, true)
	r.Route(childAddr, "scam guard 1111")
	if !strings.Contains(s.last(), "Code ta thik na") {
		t.Fatalf("bad code, got %q", s.last())
	}
	r.Route(parentAddr, "scam guard")
	g.now = func() time.Time { return time.Now().Add(guardCodeTTL + time.Minute) }
	r.Route(childAddr, "scam guard 4821")
	if g.Guardians(parentAddr) != 0 {
		t.Fatal("expired code must not pair")
	}
}

func TestGuardSelfPairRefused(t *testing.T) {
	r, s, g := newGuardRouter(t, true)
	r.Route(parentAddr, "scam guard")
	r.Route(parentAddr, "scam guard 4821")
	if g.Guardians(parentAddr) != 0 || !strings.Contains(s.last(), "Nijer code") {
		t.Fatalf("self pairing must be refused, got %q", s.last())
	}
}

func TestGuardStop(t *testing.T) {
	r, s, g := newGuardRouter(t, true)
	r.Route(parentAddr, "scam guard")
	r.Route(childAddr, "scam guard 4821")
	r.Route(childAddr, "scam guard stop")
	if g.Guardians(parentAddr) != 0 || !strings.Contains(s.last(), "bondho") {
		t.Fatalf("stop should unpair, got %q", s.last())
	}
	r.Route(childAddr, "scam guard stop")
	if !strings.Contains(s.last(), "Kono Family Guard") {
		t.Fatalf("second stop: %q", s.last())
	}
}

func TestGuardMaxThree(t *testing.T) {
	r, s, g := newGuardRouter(t, false)
	g.isSubscribed = nil
	for i, c := range []string{"tel:A", "tel:B", "tel:C", "tel:D"} {
		r.Route(parentAddr, "scam guard")
		r.Route(c, "scam guard 4821")
		if i == 3 && !strings.Contains(s.last(), "3 jon") {
			t.Fatalf("4th guardian must be refused, got %q", s.last())
		}
	}
	if g.Guardians(parentAddr) != 3 {
		t.Fatalf("want 3 guardians, got %d", g.Guardians(parentAddr))
	}
}

func TestNoAlertForLowRisk(t *testing.T) {
	r, s, _ := newGuardRouter(t, true)
	r.Route(parentAddr, "scam guard")
	r.Route(childAddr, "scam guard 4821")
	before := len(sentTo(s, childAddr))
	r.Route(parentAddr, "scam 01711111111 Ami bari ashchi, rat e dekha hobe")
	time.Sleep(150 * time.Millisecond)
	if len(sentTo(s, childAddr)) != before {
		t.Fatal("no alert for a non-high-risk message")
	}
}

func TestSignupMarksSubscriber(t *testing.T) {
	r, _, _ := newRouter(t)
	subs := NewSubscribers()
	r.signup.OnActive = subs.Add
	r.Route(masked, "scam join")
	r.Route(masked, "scam 482913")
	if !subs.Has(masked) {
		t.Fatal("successful sign-up must mark the user subscribed")
	}
}

func TestPairAppAndStatus(t *testing.T) {
	s := &fakeSender{}
	g := NewGuard(s, nil)
	g.codes["4821"] = guardCode{parent: "tel:P", at: g.now()}
	if got := g.PairApp(context.Background(), "app:demo", "9999"); got != "bad_code" {
		t.Fatalf("got %q", got)
	}
	if got := g.PairApp(context.Background(), "app:demo", "4821"); got != "" {
		t.Fatalf("got %q", got)
	}
	if !g.isGuardian("app:demo") || g.Guardians("tel:P") != 1 {
		t.Fatal("not paired")
	}
}
