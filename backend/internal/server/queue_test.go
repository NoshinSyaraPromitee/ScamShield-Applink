package server

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"
)

type flaky struct {
	mu    sync.Mutex
	fails int
	calls int
}

func (f *flaky) SendSMS(context.Context, string, string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.calls++
	if f.calls <= f.fails {
		return errors.New("down")
	}
	return nil
}

func TestRetrySenderDeliversAfterFailures(t *testing.T) {
	in := &flaky{fails: 2}
	r := NewRetrySender(in)
	r.delays = []time.Duration{5 * time.Millisecond, 5 * time.Millisecond, 5 * time.Millisecond}
	if err := r.SendSMS(context.Background(), "tel:1", "x"); err != nil {
		t.Fatal(err)
	}
	r.wg.Wait()
	in.mu.Lock()
	defer in.mu.Unlock()
	if in.calls != 3 || r.Pending() != 0 {
		t.Fatalf("calls=%d pending=%d", in.calls, r.Pending())
	}
}
