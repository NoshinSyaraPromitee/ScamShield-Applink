# Detection and evaluation (text for Proposal P5)

## How the rules engine works

Code: `backend/internal/detect/detect.go`. Deterministic, no network calls, no stored messages.

A message is scored from independent signals. Each signal adds to a score; the total sets the risk level.

| Signal | What it looks for | Weight |
|---|---|---|
| `unofficial_link` | Any link whose domain is not on the official list (gov.bd, bkash.com, nagad.com.bd, dutchbanglabank.com) | 0.35 |
| `asks_secret` | Asks for a PIN, OTP, password or "send the code" (Bangla, Banglish, English) | 0.35 |
| `urgency` | "blocked", "suspend", "within 24 hours", "জরুরি", "ajkei", "legal action" | 0.20 |
| `too_good` | Prize, lottery, cashback, bonus, gift | 0.20 |
| `pay_fast` | Fine, fee, refund, "pay now", discounts | 0.20 |
| `wrong_transfer` | "Sent money by mistake, please return" patterns (vul kore, ভুল করে) | 0.20 |
| `personal_number` | Mentions a bank/MFS/police brand but comes from an ordinary mobile number | 0.20 |

Risk: score >= 0.55 is high, >= 0.20 is medium, otherwise none.

Safeguards:
- **Known-good senders.** DMP says real traffic-case SMS come only from 01320-042207 and 01320-042227. Those senders get `low` (never "safe"), unless the message also has an unofficial link. A spoofed near-number gets no trust.
- **Warnings are not requests.** "Do not share your OTP" and "dibena" suppress `asks_secret`, so real OTP/security notices are not flagged.
- **Never "100% safe".** The lowest verdict still says the check cannot guarantee safety.
- **Optional AI second opinion.** `detect.LLMFallback` (Claude) runs only on medium results, after phone numbers and links are replaced by `[NUMBER]` / `[LINK]`. It is off unless `ANTHROPIC_API_KEY` is set, any error keeps the rules result, and a unit test checks that no number or link reaches the API. Not yet tested against the live API.
- **Link checker.** `CheckLink` (also `POST /link/check`) flags unofficial domains, lookalike brand domains (e.g. bkash-verify.xyz), URL shorteners, raw-IP links, punycode and direct .apk downloads. Official match is exact-or-subdomain, so bkash.com.evil.top is not trusted.
- **Delivery retries.** Failed SMS (including Family Guard alerts) are queued in memory and retried with backoff (2s, 10s, 30s, 2min); a restart drops the queue.

## Evaluation

Tool: `go run ./cmd/evaluate testdata/dev_set.csv` (flagged = medium or high).

**Dataset.** `backend/testdata/dev_set.csv`: 60 messages (36 scam, 24 legitimate; 40% legitimate), English 28, Bangla 16, Banglish 16. **These were written by us to cover the scam families in the problem section (MFS account lock, prize/lottery, fake traffic fine, job and scholarship fees, SIM/NID, wrong transfer). They are not real collected SMS.** Real, anonymised messages and a larger labelled set (Maha's 200-message task) are not yet part of this measurement.

| Run | n | Precision | Recall |
|---|---|---|---|
| First pass, before any tuning | 60 | 0.95 (2 false alarms) | 1.00 |
| After fixes | 60 | 1.00 | 1.00 |

Fixes made from the first-pass errors and a second pass with extra scam patterns: removed "today" as an urgency word, ignored secret-words inside "do not share" warnings, added fee/refund/wrong-transfer patterns.

**How to read this honestly:** the 1.00 figures were reached by tuning on the same 60 messages, so they are a development result, not an estimate of real-world accuracy. Expect lower numbers on unseen real SMS. The number to cite in the proposal is: "60 hand-written messages across three languages, precision 0.95 and recall 1.00 before tuning; the engine is rule-based and will miss scam wording it has no rule for." Re-run on the 200-message set before submission and quote that instead if it is ready.

## Limits

- Rules cannot understand new wording; an attacker can rephrase around keywords.
- No number blacklist is kept, by design (a wrong report must not harm an innocent person).
- Screenshot OCR is not built (roadmap). The link checker works on text only and does not fetch pages.
- The retry queue is in memory only.
