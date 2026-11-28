package detect

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestLLMFallbackSendsOnlyRedactedText(t *testing.T) {
	var got string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b, _ := io.ReadAll(r.Body)
		got = string(b)
		if r.Header.Get("x-api-key") != "k" {
			t.Error("missing api key header")
		}
		w.Write([]byte(`{"content":[{"type":"text","text":"HIGH"}]}`))
	}))
	defer srv.Close()

	fb := &LLMFallback{APIKey: "k", BaseURL: srv.URL}
	// Medium by rules: one weak signal (urgency) plus a number and a link.
	res := AnalyzeWithFallback(context.Background(), fb, "Urgent call 01712345678 see http://x.xyz/a", "")
	if strings.Contains(got, "01712345678") || strings.Contains(got, "x.xyz") {
		t.Fatalf("personal data reached the LLM: %s", got)
	}
	if res.Risk != RiskHigh {
		t.Fatalf("want high after LLM, got %s", res.Risk)
	}
}

func TestLLMErrorKeepsRulesResult(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "boom", 500)
	}))
	defer srv.Close()
	fb := &LLMFallback{APIKey: "k", BaseURL: srv.URL}
	res := AnalyzeWithFallback(context.Background(), fb, "Please pay the fee", "")
	if res.Risk != RiskMedium {
		t.Fatalf("want medium (rules only), got %s", res.Risk)
	}
}
