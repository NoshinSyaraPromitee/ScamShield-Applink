# ScamShield

SMS/USSD scam protection for Bangladesh, built on Banglalink AppLink for AppQuest 2.0.

- `app/` – Flutter app (share-to-check, Scam Simulator, helplines, Family Guard). Calls only our backend.
- `backend/` – Go backend: rules engine, AppLink webhooks (`/sms/receive`, `/ussd/receive`), `/scan/check` for the app.

## Run the backend

```
cd backend
go test ./...
APPLINK_SMS_URL=http://localhost:7000/sms/send go run ./cmd/server
go run ./cmd/evaluate testdata/messages.csv   # precision/recall
```

Env: `ADDR` (default `:8080`), `APPLINK_SMS_URL`, `APPLINK_APP_ID`, `APPLINK_PASSWORD`.
Develop against the AppLink mock server until app approval arrives; the Applink-as-a-Skill
files are proprietary and are **not** part of this repo.

## Status (honest)

| Part | State |
|---|---|
| Rules engine (MFS, government, job/prize, Bangla/Banglish/English) | Implemented, unit-tested |
| SMS forward-to-check (join multi-part, ask sender, reply) | Implemented, tested with a fake sender; **not yet run against the AppLink sandbox** |
| USSD, OTP, subscription | Not implemented (USSD webhook is a stub) |
| LLM fallback | Interface only; not wired |
| Evaluation | `testdata/messages.csv` is a 7-row sample; the real 200-message set is pending |

AppLink request/response field names were written from the public docs and must be verified in the sandbox.

## Prior work declaration

The Flutter app scaffold and the project setup were reused from our earlier PlantPal project
(project structure, tooling). All ScamShield logic is new for this competition.

## AI-use and third-party services declaration

- AI tools: Claude Code (Anthropic) was used to help write code, including the Go backend and tests; all code is reviewed by the team.
- Runtime AI: an optional LLM second opinion (Gemini/Claude) is planned for borderline messages and would receive **redacted text only** (numbers and links stripped). Not enabled in this version.
- Third-party services: Banglalink AppLink (SMS, USSD, OTP, Subscription).
- Test data: real SMS used for testing must have names and numbers removed; collection method is documented with the dataset.
