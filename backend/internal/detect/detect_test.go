package detect

import "testing"

func TestAnalyze(t *testing.T) {
	cases := []struct {
		name, msg, sender string
		want              Risk
	}{
		{"phish", "Your bKash is blocked. Send PIN now http://bkash-verify.xyz", "01712345678", RiskHigh},
		{"bangla", "জরুরি: আপনার নগদ একাউন্ট ব্লক হবে, পিন দিন", "", RiskHigh},
		{"banglish", "Apnar account block hoye jabe, joruri OTP den", "", RiskHigh},
		{"dmp trusted", "Traffic case notice from DMP", "+8801320042207", RiskLow},
		{"dmp spoof", "Traffic fine pay now http://dmp-fine.top", "01320042208", RiskHigh},
		{"legit", "Ajke raate khabo, tumi ki ashba?", "", RiskNone},
		{"wrong transfer", "Vul kore apnar bkash e 5000 taka chole gese, code ta pathan please", "01311223344", RiskMedium},
		{"otp warning is not a scam", "Your OTP for bKash app login is 4821. Do not share it with anyone.", "", RiskNone},
		{"today alone is not urgency", "Hi, are we meeting at 5pm today at the cafe?", "", RiskNone},
		{"official link", "Check your balance at https://www.bkash.com", "", RiskNone},
	}
	for _, c := range cases {
		if got := Analyze(c.msg, c.sender).Risk; got != c.want {
			t.Errorf("%s: got %s want %s", c.name, got, c.want)
		}
	}
}

func TestRedact(t *testing.T) {
	got := Redact("call 01712345678 or visit http://evil.xyz/a")
	if got != "call [NUMBER] or visit [LINK]" {
		t.Fatalf("got %q", got)
	}
}

func TestCheckLink(t *testing.T) {
	cases := []struct {
		url  string
		want string
	}{
		{"http://bkash-verify.xyz", "lookalike_domain"},
		{"https://bit.ly/abc", "shortened_link"},
		{"http://103.5.6.7/login", "ip_link"},
		{"http://files.example.top/app.apk", "apk_download"},
		{"http://xn--bkash-abc.com", "punycode_link"},
	}
	for _, c := range cases {
		found := false
		for _, r := range CheckLink(c.url).Reasons {
			if r == c.want {
				found = true
			}
		}
		if !found {
			t.Errorf("%s: want %s, got %v", c.url, c.want, CheckLink(c.url).Reasons)
		}
	}
	if v := CheckLink("https://www.bkash.com/help"); !v.Official || len(v.Reasons) != 0 {
		t.Errorf("official link flagged: %+v", v)
	}
	if v := CheckLink("https://bkash.com.evil.top"); v.Official {
		t.Error("suffix trick treated as official")
	}
}
