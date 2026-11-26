// Package applink is a minimal client for the AppLink SMS API. Written from the
// public docs; it does not include any Applink-as-a-Skill code (proprietary).
// ASSUMPTION: request/response field names follow the AppLink docs
// (dev.applink.com.bd). Verify against the mock server / sandbox.
package applink

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

type Config struct {
	SMSURL   string // APPLINK_SMS_URL, e.g. http://localhost:7000/sms/send
	AppID    string // APPLINK_APP_ID
	Password string // APPLINK_PASSWORD (API key)
	OTPRequestURL   string // APPLINK_OTP_REQUEST_URL
	OTPVerifyURL    string // APPLINK_OTP_VERIFY_URL
	SubscriptionURL string // APPLINK_SUBSCRIPTION_SEND_URL
	ChargingInfoURL string // APPLINK_SUBSCRIPTION_CHARGING_INFO_URL
}

type Client struct {
	cfg  Config
	http *http.Client
}

func New(cfg Config) *Client {
	return &Client{cfg: cfg, http: &http.Client{Timeout: 10 * time.Second}}
}

// Inbound is the MO SMS webhook body.
type Inbound struct {
	SourceAddress string `json:"sourceAddress"`
	Message       string `json:"message"`
	RequestID     string `json:"requestId"`
	Encoding      string `json:"encoding"`
}

type sendReq struct {
	Version       string   `json:"version"`
	ApplicationID string   `json:"applicationId"`
	Password      string   `json:"password"`
	Message       string   `json:"message"`
	Destinations  []string `json:"destinationAddresses"`
}

type sendResp struct {
	StatusCode   string `json:"statusCode"`
	StatusDetail string `json:"statusDetail"`
}

// SendSMS sends text to a local 01XXXXXXXXX number. AppLink can return HTTP 200
// with an error in the body, so statusCode (S1000 = success) is what we check.
func (c *Client) SendSMS(ctx context.Context, to, text string) error {
	body, _ := json.Marshal(sendReq{
		Version: "1.0", ApplicationID: c.cfg.AppID, Password: c.cfg.Password,
		Message: text, Destinations: []string{"tel:88" + strings.TrimPrefix(to, "88")},
	})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.cfg.SMSURL, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	var out sendResp
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return fmt.Errorf("applink: bad response (http %d): %w", resp.StatusCode, err)
	}
	if out.StatusCode != "S1000" {
		return fmt.Errorf("applink: %s %s", out.StatusCode, out.StatusDetail)
	}
	return nil
}
