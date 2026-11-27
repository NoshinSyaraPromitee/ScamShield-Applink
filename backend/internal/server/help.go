package server

import (
"context"
"encoding/json"
"fmt"
"log"
"os"
"strings"
"sync"
"time"
)

// Help runs "scam help" over SMS: the fixed emergency tree from
// content/emergency_tree.json, one question per SMS. The user answers with
// "scam <number>". No AI-generated advice: every word comes from the file.
type Help struct {
tree helpTree
send Sender

mu       sync.Mutex
sessions map[string]helpSession // user (raw sourceAddress) -> current node
now      func() time.Time
}

const (
helpTTL      = 10 * time.Minute
helpMaxSteps = 3 // keep the final SMS short; the app has the full guide
msgHelpPick  = "Number ta likhun, jemon: scam 1"
)

type helpSession struct {
node string
at   time.Time
}

type helpTree struct {
Root     string              `json:"root"`
Hotlines []helpHotline       `json:"hotlines"`
Nodes    map[string]helpNode `json:"nodes"`
}

type helpHotline struct {
ID     string `json:"id"`
NameBn string `json:"name_bn"`
Number string `json:"number"`
}

type helpNode struct {
QBn      string       `json:"q_bn"`
Options  []helpOption `json:"options"`
End      bool         `json:"end"`
StepsBn  []string     `json:"steps_bn"`
Hotlines []string     `json:"hotlines"`
}

type helpOption struct {
Key  string `json:"key"`
Bn   string `json:"bn"`
Next string `json:"next"`
}

// LoadHelp reads the emergency tree JSON (UTF-8, BOM tolerated).
func LoadHelp(path string, send Sender) (*Help, error) {
raw, err := os.ReadFile(path)
if err != nil {
return nil, err
}
raw = []byte(strings.TrimPrefix(string(raw), "\xef\xbb\xbf"))
var t helpTree
if err := json.Unmarshal(raw, &t); err != nil {
return nil, fmt.Errorf("emergency tree: %w", err)
}
if _, ok := t.Nodes[t.Root]; !ok {
return nil, fmt.Errorf("emergency tree: root %q missing", t.Root)
}
return &Help{tree: t, send: send, sessions: map[string]helpSession{}, now: time.Now}, nil
}

// Waiting reports whether user is in the middle of the help tree.
func (h *Help) Waiting(user string) bool {
h.mu.Lock()
defer h.mu.Unlock()
s, ok := h.sessions[user]
if ok && h.now().Sub(s.at) > helpTTL {
delete(h.sessions, user)
return false
}
return ok
}

// Start sends the first question.
func (h *Help) Start(ctx context.Context, user string) {
h.goTo(ctx, user, h.tree.Root)
}

// Choose handles "scam <key>" while the user is in the tree.
func (h *Help) Choose(ctx context.Context, user, key string) {
h.mu.Lock()
s, ok := h.sessions[user]
h.mu.Unlock()
if !ok {
h.Start(ctx, user)
return
}
for _, o := range h.tree.Nodes[s.node].Options {
if o.Key == key {
h.goTo(ctx, user, o.Next)
return
}
}
h.reply(ctx, user, msgHelpPick)
}

func (h *Help) goTo(ctx context.Context, user, id string) {
n, ok := h.tree.Nodes[id]
if !ok {
id, n = h.tree.Root, h.tree.Nodes[h.tree.Root]
}
h.mu.Lock()
if n.End {
delete(h.sessions, user)
} else {
h.sessions[user] = helpSession{node: id, at: h.now()}
}
h.mu.Unlock()

if n.End {
h.reply(ctx, user, h.renderEnd(n))
} else {
h.reply(ctx, user, renderQuestion(n))
}
}

func renderQuestion(n helpNode) string {
var b strings.Builder
b.WriteString(n.QBn)
for _, o := range n.Options {
fmt.Fprintf(&b, "\n%s %s", o.Key, o.Bn)
}
b.WriteString("\nUttor: scam <number>")
return b.String()
}

func (h *Help) renderEnd(n helpNode) string {
var b strings.Builder
steps := n.StepsBn
if len(steps) > helpMaxSteps {
steps = steps[:helpMaxSteps]
}
for i, s := range steps {
if i > 0 {
b.WriteString("\n")
}
fmt.Fprintf(&b, "%d) %s", i+1, s)
}
var calls []string
for _, id := range n.Hotlines {
for _, hl := range h.tree.Hotlines {
if hl.ID == id {
calls = append(calls, hl.NameBn+" "+hl.Number)
}
}
}
if len(calls) > 0 {
b.WriteString("\nCall: " + strings.Join(calls, ", "))
}
b.WriteString("\n- ScamShield")
return b.String()
}

func (h *Help) reply(ctx context.Context, to, text string) {
if err := h.send.SendSMS(ctx, to, text); err != nil {
log.Printf("help: send failed: %v", err)
}
}

// isChoice reports whether s is a single menu digit (1-9).
func isChoice(s string) bool {
return len(s) == 1 && s[0] >= '1' && s[0] <= '9'
}