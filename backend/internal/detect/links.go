package detect

import (
	"net/url"
	"regexp"
	"strings"
)

var (
	shorteners = []string{"bit.ly", "tinyurl.com", "t.co", "goo.gl", "cutt.ly", "is.gd", "rb.gy", "ow.ly", "shorturl.at"}
	ipHostRe   = regexp.MustCompile(`^\d{1,3}(\.\d{1,3}){3}$`)
	// Brands scammers imitate. A domain containing one of these that is not
	// an official domain is a lookalike.
	brandWords = []string{"bkash", "nagad", "rocket", "upay", "dmp", "btrc", "gov-bd", "grameenphone", "banglalink", "robi", "dutchbangla"}
)

// LinkVerdict explains why a link looks unsafe. Empty Reasons means no
// red flag was found (not a guarantee that it is safe).
type LinkVerdict struct {
	Host     string   `json:"host"`
	Official bool     `json:"official"`
	Reasons  []string `json:"reasons"`
}

func hostOf(raw string) string {
	if !strings.Contains(raw, "://") {
		raw = "http://" + raw
	}
	u, err := url.Parse(raw)
	if err != nil {
		return ""
	}
	return strings.ToLower(u.Hostname())
}

func isOfficialHost(h string) bool {
	for _, d := range officialDomains {
		if h == d || strings.HasSuffix(h, "."+d) {
			return true
		}
	}
	return false
}

// CheckLink inspects one link: official-domain list, lookalike brand domains,
// URL shorteners, raw IPs, punycode, and direct app (.apk) downloads.
func CheckLink(raw string) LinkVerdict {
	h := hostOf(raw)
	v := LinkVerdict{Host: h, Official: isOfficialHost(h), Reasons: []string{}}
	if h == "" || v.Official {
		return v
	}
	v.Reasons = append(v.Reasons, "unofficial_link")
	for _, s := range shorteners {
		if h == s {
			v.Reasons = append(v.Reasons, "shortened_link")
		}
	}
	if ipHostRe.MatchString(h) {
		v.Reasons = append(v.Reasons, "ip_link")
	}
	if strings.Contains(h, "xn--") {
		v.Reasons = append(v.Reasons, "punycode_link")
	}
	for _, b := range brandWords {
		if strings.Contains(h, b) {
			v.Reasons = append(v.Reasons, "lookalike_domain")
			break
		}
	}
	if strings.HasSuffix(strings.ToLower(strings.SplitN(raw, "?", 2)[0]), ".apk") {
		v.Reasons = append(v.Reasons, "apk_download")
	}
	return v
}
