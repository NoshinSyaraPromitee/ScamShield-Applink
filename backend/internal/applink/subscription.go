// OTP sign-up and subscription calls. Written by the ScamShield team from the
// public Applink docs; no Applink-as-a-Skill code is copied here.
//
// Rules this file follows (from the Applink docs):
//   - Applink answers HTTP 200 even for errors: success is statusCode "S1000".
//   - For subscription calls, S1000 only means "processed". Whether the user is
//     subscribed is in subscriptionStatus (e.g. "REGISTERED", sometimes with a
//     trailing dot), so we compare it trimmed, upper-cased, by prefix.
//   - subscriberId may be masked. Store it exactly as Applink returns it and use
//     it for every later call; never rebuild it from a phone number.
//   - Every OTP request costs money and sends an SMS: never use it as a login.
package applink

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
)

// Status codes we branch on.
const (
	codeSuccess    = "S1000"
	CodeWrongOTP   = "E1850" // re-prompt with the same referenceNo
	CodeExpiredOTP = "E1851" // OTP expired: request a new one
)

// APIError is a non-S1000 answer from Applink.
type APIError struct {
	Code, Detail string
}

func (e *APIError) Error() string { return "applink: " + e.Code + " " + e.Detail }

// IsCode reports whether err is an Applink error with the given status code.
func IsCode(err error, code string) bool {
	var ae *APIError
	return errors.As(err, &ae) && ae.Code == code
}

// post sends body (plus applicationId/password) to url and decodes the reply
// into out. It returns an *APIError when statusCode is not S1000.
func (c *Client) post(ctx context.Context, url string, body map[string]any, out any) error {
	if url == "" {
		return errors.New("applink: endpoint URL not configured")
	}
	body["applicationId"] = c.cfg.AppID
	body["password"] = c.cfg.Password
	raw, err := json.Marshal(body)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(raw))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json;charset=utf-8")
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var buf bytes.Buffer
	if _, err := buf.ReadFrom(resp.Body); err != nil {
		return err
	}
	var status struct {
		StatusCode   string `json:"statusCode"`
		StatusDetail string `json:"statusDetail"`
	}
	if err := json.Unmarshal(buf.Bytes(), &status); err != nil {
		return fmt.Errorf("applink: bad response (http %d): %w", resp.StatusCode, err)
	}
	if status.StatusCode != codeSuccess {
		return &APIError{Code: status.StatusCode, Detail: status.StatusDetail}
	}
	if out != nil {
		return json.Unmarshal(buf.Bytes(), out)
	}
	return nil
}

// statusIs compares an Applink subscriptionStatus such as "REGISTERED." safely.
func statusIs(got, want string) bool {
	return strings.HasPrefix(strings.ToUpper(strings.TrimSpace(got)), want)
}

// Active reports whether a subscriptionStatus means the paid plan is usable.
func Active(status string) bool {
	return statusIs(status, "REGISTERED") || statusIs(status, "TRIAL")
}

// RequestOTP asks Applink to text an OTP to subscriberID ("tel:8801XXXXXXXXX"
// or a masked id). Keep the returned referenceNo on the server for 5 minutes;
// never send it to the client.
func (c *Client) RequestOTP(ctx context.Context, subscriberID string) (referenceNo string, err error) {
	var out struct {
		ReferenceNo string `json:"referenceNo"`
	}
	err = c.post(ctx, c.cfg.OTPRequestURL, map[string]any{
		"subscriberId":    subscriberID,
		"applicationHash": "scamshd1", // used by Android SMS auto-read; any 8 chars
		"applicationMetaData": map[string]string{
			"client":  "MOBILEAPP",
			"device":  "unknown",
			"os":      "android",
			"appCode": "https://github.com/NoshinSyaraPromitee/ScamShield-Applink",
		},
	}, &out)
	if err != nil {
		return "", err
	}
	if out.ReferenceNo == "" {
		return "", errors.New("applink: OTP request succeeded without referenceNo")
	}
	return out.ReferenceNo, nil
}

// VerifyResult is what a successful OTP verification gives us.
type VerifyResult struct {
	SubscriberID string // store exactly as returned (may be masked)
	Status       string // e.g. REGISTERED
}

// VerifyOTP checks the code the user typed. Success subscribes the user.
// Use IsCode(err, CodeWrongOTP) / IsCode(err, CodeExpiredOTP) to re-prompt.
func (c *Client) VerifyOTP(ctx context.Context, referenceNo, otp string) (VerifyResult, error) {
	var out struct {
		SubscriberID       string `json:"subscriberId"`
		SubscriptionStatus string `json:"subscriptionStatus"`
	}
	err := c.post(ctx, c.cfg.OTPVerifyURL, map[string]any{
		"referenceNo": referenceNo,
		"otp":         strings.TrimSpace(otp),
	}, &out)
	if err != nil {
		return VerifyResult{}, err
	}
	return VerifyResult{SubscriberID: out.SubscriberID, Status: out.SubscriptionStatus}, nil
}

// setSubscription sends action "1" (subscribe) or "0" (unsubscribe) and
// returns the resulting subscriptionStatus.
func (c *Client) setSubscription(ctx context.Context, subscriberID, action string) (string, error) {
	var out struct {
		SubscriptionStatus string `json:"subscriptionStatus"`
	}
	err := c.post(ctx, c.cfg.SubscriptionURL, map[string]any{
		"subscriberId": subscriberID,
		"action":       action,
	}, &out)
	return out.SubscriptionStatus, err
}

// Subscribe opts the user in. Only deliver the paid service once the status is
// REGISTERED (REG_PENDING / INITIAL means "not yet": wait for the notification).
func (c *Client) Subscribe(ctx context.Context, subscriberID string) (status string, err error) {
	return c.setSubscription(ctx, subscriberID, "1")
}

// Unsubscribe opts the user out ("unreg scam"). UNREGISTERED is success even if
// the user was never subscribed.
func (c *Client) Unsubscribe(ctx context.Context, subscriberID string) error {
	status, err := c.setSubscription(ctx, subscriberID, "0")
	if err != nil {
		return err
	}
	if !statusIs(status, "UNREGISTERED") {
		return fmt.Errorf("applink: unsubscribe left status %q", status)
	}
	return nil
}

// ChargingInfo is one subscriber's plan status.
type ChargingInfo struct {
	SubscriberID       string `json:"subscriberId"`
	SubscriptionStatus string `json:"subscriptionStatus"`
	LastChargedDate    string `json:"lastChargedDate"`   // empty if never charged
	LastChargedAmount  string `json:"lastChargedAmount"` // e.g. "30.00 BDT"
	StatusCode         string `json:"statusCode"`
	StatusDetail       string `json:"statusDetail"`
}

// GetChargingInfo looks up up to 10 subscribers. Check each entry's StatusCode
// and use Active(entry.SubscriptionStatus) to decide access.
func (c *Client) GetChargingInfo(ctx context.Context, subscriberIDs ...string) ([]ChargingInfo, error) {
	if len(subscriberIDs) == 0 || len(subscriberIDs) > 10 {
		return nil, errors.New("applink: charging info takes 1 to 10 subscribers")
	}
	var out struct {
		DestinationResponses []ChargingInfo `json:"destinationResponses"`
	}
	err := c.post(ctx, c.cfg.ChargingInfoURL, map[string]any{
		"subscriberIds": subscriberIDs,
	}, &out)
	return out.DestinationResponses, err
}
