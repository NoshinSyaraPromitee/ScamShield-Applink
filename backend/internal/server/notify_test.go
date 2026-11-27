package server

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func notify(t *testing.T, srv *Server, body string) string {
	t.Helper()
	rec := httptest.NewRecorder()
	srv.Handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/subscription/notify", bytes.NewBufferString(body)))
	return rec.Body.String()
}

func TestSubscriptionNotifyAddsAndRemoves(t *testing.T) {
	r, _, _ := newRouter(t)
	subs := NewSubscribers()
	srv := New(r, nil).WithSubscriptions(subs, "APP_1", "secret")

	out := notify(t, srv, `{"applicationId":"APP_1","password":"secret","subscriberId":"`+masked+`","status":"REGISTERED"}`)
	if !strings.Contains(out, "S1000") || !subs.Has(masked) {
		t.Fatalf("REGISTERED should add: %s", out)
	}
	notify(t, srv, `{"applicationId":"APP_1","password":"secret","subscriberId":"`+masked+`","status":"UNREGISTERED"}`)
	if subs.Has(masked) {
		t.Fatal("UNREGISTERED should remove")
	}
}

func TestSubscriptionNotifyRejectsWrongPassword(t *testing.T) {
	r, _, _ := newRouter(t)
	subs := NewSubscribers()
	srv := New(r, nil).WithSubscriptions(subs, "APP_1", "secret")
	out := notify(t, srv, `{"applicationId":"APP_1","password":"nope","subscriberId":"`+masked+`","status":"REGISTERED"}`)
	if !strings.Contains(out, "S1000") || subs.Has(masked) {
		t.Fatalf("forged notification must be ignored (still S1000): %s", out)
	}
}

func TestOtherCallbacksAck(t *testing.T) {
	r, _, _ := newRouter(t)
	srv := New(r, nil)
	for _, p := range []string{"/sms/report", "/caas/notify"} {
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPost, p, bytes.NewBufferString(`{}`)))
		if !strings.Contains(rec.Body.String(), "S1000") {
			t.Fatalf("%s should answer S1000", p)
		}
	}
}
