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
