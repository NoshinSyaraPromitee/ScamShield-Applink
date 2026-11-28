package server

import (
	"context"
	"crypto/rand"
	"fmt"
	"log"
	"math/big"
	"strings"
	"sync"
	"time"
)

// Guard runs Family Guard over SMS.
//
// parent: scam guard          -> gets a 4-digit code (parent opts in = consent)
// child:  scam guard 4821     -> paired (child must have the paid plan)
// either: scam guard stop     -> unpaired
//
// When a parent's forwarded message is HIGH risk, every paired child gets a
// short alert. The alert never contains the message text or any number.
// Users are keyed by the raw sourceAddress (number masking is ON).
// State is in memory for the demo: a restart means pairing again.
type Guard struct {
	send         Sender
	isSubscribed func(user string) bool // nil = no plan check (demo mode)

	mu        sync.Mutex
	codes     map[string]guardCode // code -> parent
	guardians map[string][]string  // parent -> children
	// DemoCode, if set (env GUARD_DEMO_CODE), always pairs the app so a demo
	// works without a real parent phone. Leave empty in production.
	DemoCode string

	now     func() time.Time
	newCode func() string
}

type guardCode struct {
	parent string
	at     time.Time
}

const (
	guardCodeTTL = 15 * time.Minute
	maxGuardians = 3

	msgGuardCode    = "Apnar Family Guard code: %s. Apnar shontan ke bolun 21213 e likhte: scam guard %s (15 min). - ScamShield"
	msgGuardPaired  = "Family Guard chalu. - ScamShield"
	msgGuardNeedSub = "Family Guard er jonno age likhun: scam join (Tk 30/mash). Tarpor abar: scam guard <code>"
	msgGuardBadCode = "Code ta thik na ba meyad shesh. Parent ke abar likhte bolun: scam guard"
	msgGuardFull    = "Ei member er jonno already 3 jon guardian ache. - ScamShield"
	msgGuardSelf    = "Nijer code nije dewa jabe na. Code ta apnar shontan ke din."
	msgGuardStopped = "Family Guard bondho kora holo. - ScamShield"
	msgGuardNone    = "Kono Family Guard chalu nei. - ScamShield"
	msgGuardAlert   = "ScamShield: Apnar Family Guard member ekta high-risk message check korechen. Ekhoni call kore khoj nin."
)

func NewGuard(send Sender, isSubscribed func(user string) bool) *Guard {
	return &Guard{
		send: send, isSubscribed: isSubscribed,
		codes: map[string]guardCode{}, guardians: map[string][]string{},
		now: time.Now, newCode: randomCode,
	}
}

// Handle runs "scam guard <arg>"; arg is "" , "stop" or a code.
func (g *Guard) Handle(ctx context.Context, user, arg string) {
	switch arg = strings.TrimSpace(arg); {
	case arg == "":
		g.begin(ctx, user)
	case arg == "stop":
		g.stop(ctx, user)
	default:
		g.pair(ctx, user, arg)
	}
}

func (g *Guard) begin(ctx context.Context, parent string) {
	g.mu.Lock()
	for c, v := range g.codes { // one live code per parent
		if v.parent == parent {
			delete(g.codes, c)
		}
	}
	code := g.newCode()
	for _, taken := g.codes[code]; taken; _, taken = g.codes[code] {
		code = g.newCode()
	}
	g.codes[code] = guardCode{parent: parent, at: g.now()}
	g.mu.Unlock()
	g.reply(ctx, parent, fmt.Sprintf(msgGuardCode, code, code))
}

func (g *Guard) pair(ctx context.Context, child, code string) {
	g.mu.Lock()
	c, ok := g.codes[code]
	if ok && g.now().Sub(c.at) > guardCodeTTL {
		delete(g.codes, code)
		ok = false
	}
	g.mu.Unlock()

	switch {
	case !ok:
		g.reply(ctx, child, msgGuardBadCode)
		return
	case c.parent == child:
		g.reply(ctx, child, msgGuardSelf)
		return
	case g.isSubscribed != nil && !g.isSubscribed(child):
		g.reply(ctx, child, msgGuardNeedSub) // code stays valid until it expires
		return
	}

	g.mu.Lock()
	list := g.guardians[c.parent]
	already := contains(list, child)
	full := !already && len(list) >= maxGuardians
	if !already && !full {
		g.guardians[c.parent] = append(list, child)
	}
	if !full {
		delete(g.codes, code)
	}
	g.mu.Unlock()

	if full {
		g.reply(ctx, child, msgGuardFull)
		return
	}
	g.reply(ctx, child, msgGuardPaired)
	g.reply(ctx, c.parent, msgGuardPaired)
}

func (g *Guard) stop(ctx context.Context, user string) {
	g.mu.Lock()
	_, wasParent := g.guardians[user]
	delete(g.guardians, user)
	wasChild := false
	for p, list := range g.guardians {
		if i := indexOf(list, user); i >= 0 {
			wasChild = true
			list = append(list[:i], list[i+1:]...)
			if len(list) == 0 {
				delete(g.guardians, p)
			} else {
				g.guardians[p] = list
			}
		}
	}
	g.mu.Unlock()
	if wasParent || wasChild {
		g.reply(ctx, user, msgGuardStopped)
	} else {
		g.reply(ctx, user, msgGuardNone)
	}
}

// Alert tells every guardian of parent that a high-risk message was checked.
func (g *Guard) Alert(ctx context.Context, parent string) {
	g.mu.Lock()
	children := append([]string(nil), g.guardians[parent]...)
	g.mu.Unlock()
	for _, c := range children {
		g.reply(ctx, c, msgGuardAlert)
	}
}

// Guardians returns how many guardians parent has (for tests and logs).
func (g *Guard) Guardians(parent string) int {
	g.mu.Lock()
	defer g.mu.Unlock()
	return len(g.guardians[parent])
}

func (g *Guard) reply(ctx context.Context, to, text string) {
	if err := g.send.SendSMS(ctx, to, text); err != nil {
		log.Printf("guard: send failed: %v", err)
	}
}

func randomCode() string {
	n, err := rand.Int(rand.Reader, big.NewInt(9000))
	if err != nil {
		return fmt.Sprintf("%04d", time.Now().UnixNano()%9000+1000)
	}
	return fmt.Sprintf("%04d", n.Int64()+1000)
}

func contains(list []string, s string) bool { return indexOf(list, s) >= 0 }

func indexOf(list []string, s string) int {
	for i, v := range list {
		if v == s {
			return i
		}
	}
	return -1
}

// Subscribers remembers who has the paid plan (in memory for the demo).
// Filled when OTP sign-up succeeds; /subscription/notify should update it later.
type Subscribers struct {
	mu sync.Mutex
	m  map[string]bool
}

func NewSubscribers() *Subscribers { return &Subscribers{m: map[string]bool{}} }

func (s *Subscribers) Add(user string) {
	s.mu.Lock()
	s.m[user] = true
	s.mu.Unlock()
}

func (s *Subscribers) Remove(user string) {
	s.mu.Lock()
	delete(s.m, user)
	s.mu.Unlock()
}

func (s *Subscribers) Has(user string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.m[user]
}
