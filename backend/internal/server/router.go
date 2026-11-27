package server

import (
"context"
"log"
"strings"
"time"
"unicode"
)

// Router decides what to do with each inbound SMS on the shared code 21213.
// Everything reaches us as "scam <text>" (the keyword may or may not still be
// at the front, and later parts of a long message never have it):
//
//scam join          -> start paid sign-up (OTP)      Signup
//scam 482913        -> OTP reply while sign-up waits  Signup
//scam help          -> emergency guide (tree)        Help
//scam 2             -> menu choice while in help     Help
//scam guard [code]  -> Family Guard pairing          Guard
//anything else      -> scam check                    Forwarder
//
// "unreg scam" is not routed here: AppLink handles it on the shared code and
// tells us through /subscription/notify (to be confirmed with AppLink).
//
// The user key is the raw sourceAddress exactly as AppLink sent it, because
// number masking is ON for our app. Never rebuild it from digits.
type Router struct {
send   Sender
fwd    *Forwarder
signup *Signup
help   *Help  // nil until the emergency tree is loaded; then "help" uses it
guard  *Guard // nil = Family Guard placeholder reply
// run executes command work off the webhook goroutine, so AppLink gets its
// S1000 at once. Tests replace it with a synchronous call.
run func(func(ctx context.Context))
}

const commandTimeout = 30 * time.Second

func NewRouter(send Sender, fwd *Forwarder, signup *Signup) *Router {
return &Router{send: send, fwd: fwd, signup: signup, run: background}
}

// WithHelp enables the real "scam help" flow (emergency tree over SMS).
func (r *Router) WithHelp(h *Help) *Router {
r.help = h
return r
}

// WithGuard enables Family Guard pairing over SMS.
func (r *Router) WithGuard(g *Guard) *Router {
r.guard = g
return r
}

func background(f func(ctx context.Context)) {
go func() {
ctx, cancel := context.WithTimeout(context.Background(), commandTimeout)
defer cancel()
f(ctx)
}()
}

const keyword = "scam"

// Fallback replies, used only when Help/Guard are not configured.
// Hotlines here must stay the verified ones from content/emergency_tree.json.
const (
helpPlaceholder = "Protarito hole ekhoni: PIN bodlan. bKash 16247, Nagad 16167, joruri 999. Puro guide shighroi. - ScamShield"
guardSoon       = "Family Guard pairing shighroi chalu hobe. - ScamShield"
)

// Route handles one inbound SMS part from user (raw sourceAddress). It returns
// quickly: commands run in the background, and scam checks are already
// buffered by the Forwarder (which keeps the parts of a long message in order).
func (r *Router) Route(user, message string) {
text := stripKeyword(message)
cmd := strings.ToLower(text)

switch {
case cmd == "join":
r.run(func(ctx context.Context) { r.signup.Start(ctx, user) })
case isCode(cmd) && r.signup.Waiting(user):
r.run(func(ctx context.Context) { r.signup.Verify(ctx, user, cmd) })
case cmd == "help" && r.help != nil:
r.run(func(ctx context.Context) { r.help.Start(ctx, user) })
case cmd == "help":
r.run(func(ctx context.Context) { r.reply(ctx, user, helpPlaceholder) })
case r.help != nil && isChoice(cmd) && r.help.Waiting(user):
r.run(func(ctx context.Context) { r.help.Choose(ctx, user, cmd) })
case (cmd == "guard" || strings.HasPrefix(cmd, "guard ")) && r.guard != nil:
arg := strings.TrimPrefix(cmd, "guard")
r.run(func(ctx context.Context) { r.guard.Handle(ctx, user, arg) })
case cmd == "guard" || strings.HasPrefix(cmd, "guard "):
r.run(func(ctx context.Context) { r.reply(ctx, user, guardSoon) })
default:
// Forward-to-check. Pass the text without the keyword, so the
// detector never sees "scam" as part of the suspicious message.
r.fwd.Receive(user, text)
}
}

func (r *Router) reply(ctx context.Context, to, text string) {
if err := r.send.SendSMS(ctx, to, text); err != nil {
log.Printf("router: send failed: %v", err)
}
}

// stripKeyword removes a leading "scam" (any case) and surrounding spaces.
// "scammer" is left alone: only the whole word is removed.
func stripKeyword(message string) string {
t := strings.TrimSpace(message)
if len(t) >= len(keyword) && strings.EqualFold(t[:len(keyword)], keyword) {
rest := t[len(keyword):]
if rest == "" || unicode.IsSpace(rune(rest[0])) {
return strings.TrimSpace(rest)
}
}
return t
}

// isCode reports whether s looks like an OTP: 4 to 8 digits only.
func isCode(s string) bool {
if len(s) < 4 || len(s) > 8 {
return false
}
for _, c := range s {
if c < '0' || c > '9' {
return false
}
}
return true
}