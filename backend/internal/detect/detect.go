// Package detect is the ScamShield rules engine. It mirrors the Flutter
// offline analyzer (app/lib/core/network/mock/mock_scan_analyzer.dart) and adds
// Banglish keywords. Rules are deterministic; an optional LLM fallback only
// runs on borderline results and only ever sees redacted text.
package detect

import (
	"context"
	"regexp"
	"strings"
)

type Risk string

const (
	RiskNone   Risk = "none"
	RiskLow    Risk = "low"
	RiskMedium Risk = "medium"
	RiskHigh   Risk = "high"
)

type Result struct {
	Risk       Risk     `json:"risk"`
	Score      float64  `json:"score"`
	Reasons    []string `json:"reasons"`
	Highlights []string `json:"highlights"`
}

// Fallback is an optional second opinion for borderline (medium) messages.
// Implementations MUST receive redacted text only (see Redact).
type Fallback interface {
	Classify(ctx context.Context, redacted string) (Risk, error)
}

var (
	officialDomains = []string{"gov.bd", "bkash.com", "nagad.com.bd", "dutchbanglabank.com"}
	// DMP traffic-case SMS come only from these numbers.
	trustedSenders = map[string]bool{"01320042207": true, "01320042227": true}

	linkRe  = regexp.MustCompile(`(?i)(https?://)?([a-z0-9-]+\.)+(xyz|top|click|info|link|site|online|live|com|net|org|bd)(/\S*)?`)
	brandRe = regexp.MustCompile(`(?i)bkash|nagad|rocket|bank|dmp|traffic|police|বিকাশ|নগদ|ব্যাংক|পুলিশ`)

	rules = []struct {
		code  string
		words []string
	}{
		{"urgency", []string{"urgent", "immediately", "within 24", "blocked", "suspend", "legal action", "joruri", "ajkei", "block hoye", "জরুরি", "ব্লক", "আজই", "২৪ ঘণ্টা", "বন্ধ হয়ে"}},
		{"asks_secret", []string{"pin", "otp", "password", "code den", "code pathan", "share the code", "send the code", "পিন", "ওটিপি", "পাসওয়ার্ড"}},
		{"too_good", []string{"won", "cashback", "prize", "lottery", "bonus", "gift", "puroskar", "ক্যাশব্যাক", "পুরস্কার", "লটারি", "উপহার"}},
		{"pay_fast", []string{"% off", "discount", "pay now", "fine", "fee", "refund", "jorimana", "ছাড়", "জরিমানা", "ফি", "ফেরত"}},
		{"wrong_transfer", []string{"wrong transaction", "by mistake", "vul kore", "ভুল করে"}},
	}

	// Phrases that mean the message WARNS about secrets rather than asks for them.
	warnRe = regexp.MustCompile(`(?i)do not share|don.t share|never share|শেয়ার করবেন না|কাউকে দেবেন না|dibena|dien na`)

	phoneRe = regexp.MustCompile(`(?:\+?88)?01[3-9]\d{8}`)
	asciiRe = regexp.MustCompile(`^[\x00-\x7F]+$`)
)

// NormalizeNumber returns a local 01XXXXXXXXX number, or "" if s isn't one.
func NormalizeNumber(s string) string {
	var b strings.Builder
	for _, r := range s {
		if r >= '0' && r <= '9' {
			b.WriteRune(r)
		}
	}
	d := strings.TrimPrefix(b.String(), "88")
	if len(d) == 11 && strings.HasPrefix(d, "01") {
		return d
	}
	return ""
}

func find(text, word string) string {
	lower := strings.ToLower(text)
	w := strings.ToLower(word)
	if asciiRe.MatchString(word) {
		re := regexp.MustCompile(`(?i)(^|[^A-Za-z])` + regexp.QuoteMeta(w) + `($|[^A-Za-z])`)
		if re.MatchString(lower) {
			return word
		}
		return ""
	}
	if strings.Contains(text, word) {
		return word
	}
	return ""
}

// Analyze scores a message. sender may be empty/unknown.
func Analyze(message, sender string) Result {
	var reasons, highlights []string
	seenR, seenH := map[string]bool{}, map[string]bool{}
	flag := func(code, text string) {
		if !seenR[code] {
			seenR[code] = true
			reasons = append(reasons, code)
		}
		if text != "" && !seenH[text] {
			seenH[text] = true
			highlights = append(highlights, text)
		}
	}

	for _, u := range linkRe.FindAllString(message, -1) {
		for _, code := range CheckLink(u).Reasons {
			flag(code, u)
		}
	}
	warns := warnRe.MatchString(message)
	for _, r := range rules {
		if warns && r.code == "asks_secret" {
			continue
		}
		for _, w := range r.words {
			if f := find(message, w); f != "" {
				flag(r.code, f)
			}
		}
	}

	local := NormalizeNumber(sender)
	trusted := trustedSenders[local]
	if !trusted && local != "" && brandRe.MatchString(message) {
		flag("personal_number", "")
	}

	var score float64
	for _, r := range reasons {
		if r == "asks_secret" || r == "unofficial_link" || r == "lookalike_domain" || r == "apk_download" {
			score += 0.35
		} else {
			score += 0.2
		}
	}
	if score > 1 {
		score = 1
	}

	var risk Risk
	switch {
	case trusted && !seenR["unofficial_link"]:
		risk = RiskLow // never "100% safe"
	case score >= 0.55:
		risk = RiskHigh
	case score >= 0.2:
		risk = RiskMedium
	default:
		risk = RiskNone
	}
	if reasons == nil {
		reasons = []string{}
	}
	if highlights == nil {
		highlights = []string{}
	}
	return Result{Risk: risk, Score: score, Reasons: reasons, Highlights: highlights}
}

// Redact strips phone numbers and URLs so no personal data reaches an LLM.
func Redact(message string) string {
	m := phoneRe.ReplaceAllString(message, "[NUMBER]")
	return linkRe.ReplaceAllString(m, "[LINK]")
}

// AnalyzeWithFallback runs the rules, then asks fb (if set) only about
// medium-risk results. Any fallback error keeps the rules result.
func AnalyzeWithFallback(ctx context.Context, fb Fallback, message, sender string) Result {
	res := Analyze(message, sender)
	if fb == nil || res.Risk != RiskMedium {
		return res
	}
	if r, err := fb.Classify(ctx, Redact(message)); err == nil && (r == RiskHigh || r == RiskLow) {
		res.Risk = r
		res.Reasons = append(res.Reasons, "llm_second_opinion")
	}
	return res
}
