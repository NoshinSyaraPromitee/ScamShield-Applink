package main

import (
"log"
"net/http"
"os"

"github.com/scamshield/backend/internal/applink"
"github.com/scamshield/backend/internal/server"
)

func main() {
client := applink.New(applink.Config{
SMSURL:          env("APPLINK_SMS_URL", "http://localhost:7000/sms/send"),
AppID:           os.Getenv("APPLINK_APP_ID"),
Password:        os.Getenv("APPLINK_PASSWORD"),
OTPRequestURL:   os.Getenv("APPLINK_OTP_REQUEST_URL"),
OTPVerifyURL:    os.Getenv("APPLINK_OTP_VERIFY_URL"),
SubscriptionURL: os.Getenv("APPLINK_SUBSCRIPTION_SEND_URL"),
ChargingInfoURL: os.Getenv("APPLINK_SUBSCRIPTION_CHARGING_INFO_URL"),
})
fwd := server.NewForwarder(client, nil) // no LLM fallback wired yet
signup := server.NewSignup(client, client)
router := server.NewRouter(client, fwd, signup)

if help, err := server.LoadHelp(env("HELP_TREE", "../content/emergency_tree.json"), client); err != nil {
log.Printf("help: %v (using short placeholder reply)", err)
} else {
router.WithHelp(help)
}

// Family Guard: the child (guardian) must have the paid plan.
// GUARD_REQUIRE_SUB=false skips that check for a demo before billing is live.
subs := server.NewSubscribers()
signup.OnActive = subs.Add
isSub := subs.Has
if os.Getenv("GUARD_REQUIRE_SUB") == "false" {
isSub = nil
log.Println("guard: plan check OFF (demo mode)")
}
guard := server.NewGuard(client, isSub)
fwd.OnHighRisk = guard.Alert
router.WithGuard(guard)

srv := server.New(router, nil)
addr := env("ADDR", ":8080")
log.Println("ScamShield backend listening on", addr)
log.Fatal(http.ListenAndServe(addr, srv.Handler()))
}

func env(k, d string) string {
if v := os.Getenv(k); v != "" {
return v
}
return d
}