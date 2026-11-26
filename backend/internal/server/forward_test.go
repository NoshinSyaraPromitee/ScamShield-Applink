package server

import (
	"context"
	"strings"
	"sync"
	"testing"
	"time"
)

type fakeSender struct {
	mu   sync.Mutex
	sent []string
}

func (f *fakeSender) SendSMS(_ context.Context, to, text string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.sent = append(f.sent, to+"|"+text)
	return nil
}

func (f *fakeSender) last() string {
	f.mu.Lock()
	defer f.mu.Unlock()
	if len(f.sent) == 0 {
		return ""
	}
	return f.sent[len(f.sent)-1]
}

// all returns a copy of everything sent, safe to read while senders run.
func (f *fakeSender) all() []string {
	f.mu.Lock()
	defer f.mu.Unlock()
	return append([]string(nil), f.sent...)
}

func newFwd(s Sender) *Forwarder {
	f := NewForwarder(s, nil)
	f.window = 20 * time.Millisecond
	return f
}

func TestAsksSenderThenReplies(t *testing.T) {
	s := &fakeSender{}
	f := newFwd(s)
	f.Receive("01711111111", "Your bKash is blocked, send PIN http://x.xyz")
	time.Sleep(100 * time.Millisecond)
	if !strings.Contains(s.last(), "Ke pathiyeche") {
		t.Fatalf("expected sender question, got %q", s.last())
	}
	f.Receive("01711111111", "01799999999")
	time.Sleep(100 * time.Millisecond)
	if !strings.Contains(s.last(), "SABDHAN") {
		t.Fatalf("expected high-risk verdict, got %q", s.last())
	}
}

func TestInlineSenderAndMultipartJoin(t *testing.T) {
	s := &fakeSender{}
	f := newFwd(s)
	f.Receive("01711111111", "01799999999 Your bKash is blo")
	f.Receive("01711111111", "cked, send PIN now")
	time.Sleep(100 * time.Millisecond)
	if sent := s.all(); len(sent) != 1 || !strings.Contains(s.last(), "SABDHAN") {
		t.Fatalf("got %v", sent)
	}
}
