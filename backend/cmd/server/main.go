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
		SMSURL:   env("APPLINK_SMS_URL", "http://localhost:7000/sms/send"),
		AppID:    os.Getenv("APPLINK_APP_ID"),
		Password: os.Getenv("APPLINK_PASSWORD"),
	})
	srv := server.New(server.NewForwarder(client, nil), nil) // no LLM fallback wired yet
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
