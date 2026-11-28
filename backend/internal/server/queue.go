package server

import (
	"context"
	"log"
	"sync"
	"time"
)

// RetrySender wraps a Sender. A failed SMS (network error, AppLink error) is
// kept in an in-memory pending queue and retried with backoff, so a Family
// Guard alert is not lost to a brief AppLink outage. No Redis for the MVP:
// a restart drops the queue. SMS text is never logged.
type RetrySender struct {
	inner   Sender
	delays  []time.Duration
	mu      sync.Mutex
	pending int
	wg      sync.WaitGroup
}

func NewRetrySender(inner Sender) *RetrySender {
	return &RetrySender{inner: inner,
		delays: []time.Duration{2 * time.Second, 10 * time.Second, 30 * time.Second, 2 * time.Minute}}
}

// SendSMS tries once now; on failure it queues retries and returns nil, so
// callers never block on AppLink being slow.
func (r *RetrySender) SendSMS(ctx context.Context, to, text string) error {
	if err := r.inner.SendSMS(ctx, to, text); err == nil {
		return nil
	} else {
		log.Printf("sms: send failed, queued for retry: %v", err)
	}
	r.mu.Lock()
	r.pending++
	r.mu.Unlock()
	r.wg.Add(1)
	go r.retry(to, text)
	return nil
}

func (r *RetrySender) retry(to, text string) {
	defer r.wg.Done()
	defer func() { r.mu.Lock(); r.pending--; r.mu.Unlock() }()
	for i, d := range r.delays {
		time.Sleep(d)
		ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		err := r.inner.SendSMS(ctx, to, text)
		cancel()
		if err == nil {
			return
		}
		log.Printf("sms: retry %d/%d failed: %v", i+1, len(r.delays), err)
	}
	log.Printf("sms: gave up after %d retries", len(r.delays))
}

// Pending is how many messages are still waiting to be delivered.
func (r *RetrySender) Pending() int {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.pending
}
