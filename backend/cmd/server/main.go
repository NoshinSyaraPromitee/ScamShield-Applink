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
	srv := server.New(server.NewRouter(client, fwd, signup), nil)
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
