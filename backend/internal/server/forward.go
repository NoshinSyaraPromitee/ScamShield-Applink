package server

import (
"context"
"strings"
"sync"
"time"

"github.com/scamshield/backend/internal/detect"
)

// Sender sends an SMS. Satisfied by *applink.Client; faked in tests.
type Sender interface {
SendSMS(ctx context.Context, to, text string) error
}

const (
partWindow = 3 * time.Second // wait for more parts of a long message
pendingTTL = 5 * time.Minute
askSender  = "Ke pathiyeche? Number ta reply korun (jemon 017XXXXXXXX)."
)

type buffer struct {
parts []string
timer *time.Timer
}

type pendingMsg struct {
text string
at   time.Time
}

// Forwarder implements: receive forwarded SMS -> join parts -> find sender ->
// analyse -> reply.
type Forwarder struct {
send    Sender
fb      detect.Fallback
window  time.Duration
mu      sync.Mutex
buffers map[string]*buffer
pending map[string]pendingMsg // waiting for the "who sent it" answer

// OnHighRisk, if set, runs after a HIGH-risk verdict is sent to user
// (Family Guard uses it to alert guardians). Never gets the message text.
OnHighRisk func(ctx context.Context, user string)
}

func NewForwarder(s Sender, fb detect.Fallback) *Forwarder {
return &Forwarder{send: s, fb: fb, window: partWindow,
buffers: map[string]*buffer{}, pending: map[string]pendingMsg{}}
}

// Receive handles one inbound SMS part from user `from` (local number).
// Multi-part messages are joined: processing starts after `window` of quiet.
func (f *Forwarder) Receive(from, text string) {
f.mu.Lock()
defer f.mu.Unlock()
b := f.buffers[from]
if b == nil {
b = &buffer{}
f.buffers[from] = b
}
b.parts = append(b.parts, text)
if b.timer != nil {
b.timer.Stop()
}
b.timer = time.AfterFunc(f.window, func() { f.flush(from) })
}

func (f *Forwarder) flush(from string) {
f.mu.Lock()
b := f.buffers[from]
delete(f.buffers, from)
f.mu.Unlock()
if b == nil {
return
}
f.process(context.Background(), from, strings.Join(b.parts, ""))
}

func (f *Forwarder) process(ctx context.Context, from, text string) {
text = strings.TrimSpace(text)

// Answer to "Ke pathiyeche?": a bare phone number with a pending message.
f.mu.Lock()
p, ok := f.pending[from]
delete(f.pending, from)
f.mu.Unlock()
if ok && time.Since(p.at) < pendingTTL {
if n := detect.NormalizeNumber(text); n != "" {
f.reply(ctx, from, p.text, n)
return
}
// Not a number: check the earlier message with unknown sender,
// then handle this new message below.
f.reply(ctx, from, p.text, "")
}

// "01XXXXXXXXX <message>" form.
if fields := strings.Fields(text); len(fields) > 1 {
if n := detect.NormalizeNumber(fields[0]); n != "" {
f.reply(ctx, from, strings.TrimSpace(strings.TrimPrefix(text, fields[0])), n)
return
}
}

f.mu.Lock()
f.pending[from] = pendingMsg{text: text, at: time.Now()}
f.mu.Unlock()
_ = f.send.SendSMS(ctx, from, askSender)
}

func (f *Forwarder) reply(ctx context.Context, to, msg, sender string) {
res := detect.AnalyzeWithFallback(ctx, f.fb, msg, sender)
_ = f.send.SendSMS(ctx, to, Verdict(res))
if res.Risk == detect.RiskHigh && f.OnHighRisk != nil {
f.OnHighRisk(ctx, to)
}
}

// Verdict is the user-facing Banglish reply. Never claims "100% safe".
func Verdict(r detect.Result) string {
switch r.Risk {
case detect.RiskHigh:
return "SABDHAN! Eta protarona hote pare. Link e click korben na, PIN/OTP dibena. Sondeho hole 999 e call korun. - ScamShield"
case detect.RiskMedium:
return "Sondehojonok lagche. Kauke PIN/OTP dibena; official app/number e jachai korun. - ScamShield"
case detect.RiskLow:
return "Eta known official sender theke ashche, tobu PIN/OTP kauke dibena. - ScamShield"
default:
return "Kono scam chinho paini, kintu 100% nishchit bola jay na. PIN/OTP kauke dibena. - ScamShield"
}
}