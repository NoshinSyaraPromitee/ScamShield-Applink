package server

import (
	"strings"
	"testing"
	"time"
)

func newHelpRouter(t *testing.T) (*Router, *fakeSender) {
	t.Helper()
	r, s, _ := newRouter(t)
	h, err := LoadHelp("../../../content/emergency_tree.json", s)
	if err != nil {
		t.Fatal(err)
	}
	r.WithHelp(h)
	return r, s
}

func TestHelpWalksTreeToSteps(t *testing.T) {
	r, s := newHelpRouter(t)
	r.Route(masked, "scam help")
	if !strings.Contains(s.last(), "Ki hoyeche?") || !strings.Contains(s.last(), "scam <number>") {
		t.Fatalf("expected first question, got %q", s.last())
	}
	r.Route(masked, "scam 2")
	last := s.last()
	if !strings.Contains(last, "1) ") || !strings.Contains(last, "16247") {
		t.Fatalf("expected steps with hotlines, got %q", last)
	}
	if r.help.Waiting(masked) {
		t.Fatal("session should end after the steps")
	}
}

func TestHelpSubQuestion(t *testing.T) {
	r, s := newHelpRouter(t)
	r.Route(masked, "scam help")
	r.Route(masked, "scam 1")
	if !strings.Contains(s.last(), "Code ta kon account er?") {
		t.Fatalf("expected sub-question, got %q", s.last())
	}
	r.Route(masked, "scam 1")
	if !strings.Contains(s.last(), "bKash") {
		t.Fatalf("expected MFS steps, got %q", s.last())
	}
}

func TestHelpBadChoiceReprompts(t *testing.T) {
	r, s := newHelpRouter(t)
	r.Route(masked, "scam help")
	r.Route(masked, "scam 9")
	if !strings.Contains(s.last(), msgHelpPick) || !r.help.Waiting(masked) {
		t.Fatalf("bad choice should re-prompt, got %q", s.last())
	}
}

func TestDigitOutsideHelpGoesToCheck(t *testing.T) {
	r, s := newHelpRouter(t)
	r.Route(masked, "scam 2")
	time.Sleep(100 * time.Millisecond)
	if strings.Contains(s.last(), "1) ") {
		t.Fatalf("a digit without a help session must not open steps, got %q", s.last())
	}
}

func TestHelpSessionExpires(t *testing.T) {
	r, _ := newHelpRouter(t)
	r.Route(masked, "scam help")
	r.help.now = func() time.Time { return time.Now().Add(helpTTL + time.Minute) }
	if r.help.Waiting(masked) {
		t.Fatal("help session should expire")
	}
}

func TestEveryNodeRendersShort(t *testing.T) {
	_, s := newHelpRouter(t)
	h, _ := LoadHelp("../../../content/emergency_tree.json", s)
	for id, n := range h.tree.Nodes {
		var text string
		if n.End {
			text = h.renderEnd(n)
		} else {
			text = renderQuestion(n)
		}
		if len(text) > 459 {
			t.Errorf("node %s too long (%d chars)", id, len(text))
		}
		for _, c := range text {
			if c > 127 {
				t.Errorf("node %s has non-ASCII %q", id, c)
				break
			}
		}
	}
}
