# ScamShield BD

Bangla-first scam protection for Banglalink users, built on **Banglalink AppLink** for **AppQuest 2.0** (Team Buildship, IUT).
Theme 4: Frontier Technologies & Resilient Systems · Category 12: Cybersecurity, Digital Identity & Privacy.

Users text `scam <suspicious message>` to **21213** and get a Banglish verdict with safe next steps. `scam help` walks them through what to do after being scammed. Family Guard (Tk 30/month via AppLink Subscription) lets adult children protect their parents.

## Repository

| Folder | What it is |
|---|---|
| `backend/` | Go backend: SMS router, scam rules engine, OTP sign-up + subscription, AppLink client |
| `callbacks/` | Vercel HTTPS endpoints AppLink calls (`/sms/receive`, `/sms/report`, `/caas/notify`, `/subscription/notify`); they answer `S1000` and relay to the backend |
| `app/` | Flutter app: share-to-check, result screen, Scam Simulator, offline "I've been scammed" guide, Family Guard, EN/BN |
| `content/` | `emergency_tree.json`: fixed emergency decision tree with verified hotlines (used by the app and the backend) |

## Architecture

    Banglalink user --SMS "scam ..."--> AppLink (21213)
        --> https://scamshield-callbacks.vercel.app/sms/receive   (HTTPS, always S1000)
        --> Go backend: router -> scam check | join/OTP | help | guard
        --> AppLink /sms/send --> reply SMS to the user

AppLink API calls leave from our provisioned IP (E1303). Users are keyed by the raw `sourceAddress` because number masking is ON.

## SMS commands (short code 21213)

| User sends | Result |
|---|---|
| `scam <message>` | Scam check (rules engine); asks for the sender number if missing; joins multi-part SMS |
| `scam join` → `scam <OTP>` | OTP sign-up that activates the Family Guard subscription |
| `scam help` → `scam <number>` | Emergency guide over SMS |
| `scam guard <code>` | Family Guard pairing (in progress) |
| `unreg scam` | Unsubscribe (handled by AppLink) |

## AppLink APIs used

| API | Use | Status |
|---|---|---|
| SMS (receive, send, delivery report) | Forward-to-check, replies | Implemented; app submitted for approval |
| OTP | Sign-up | Implemented, tested against the AppLink mock |
| Subscription | Family Guard Tk 30/month | Implemented, tested against the AppLink mock |
| CaaS | One-time incident report | Provisioned; roadmap |
| USSD | Feature-phone menu | Blocked: no keyword available on 213 (requested) |

## Run it

    cd backend
    go test ./...
    go run ./cmd/server                       # listens on :8080
    go run ./cmd/evaluate testdata/messages.csv

    cd app
    flutter pub get
    flutter gen-l10n
    dart run build_runner build
    flutter run -t lib/main_staging.dart

Env: `ADDR`, `APPLINK_SMS_URL`, `APPLINK_APP_ID`, `APPLINK_PASSWORD`, `APPLINK_OTP_REQUEST_URL`, `APPLINK_OTP_VERIFY_URL`, `APPLINK_SUBSCRIPTION_SEND_URL`, `APPLINK_SUBSCRIPTION_CHARGING_INFO_URL`, `HELP_TREE`.
Callbacks (Vercel): `BACKEND_URL`.

## Honest status

- Live AppLink traffic depends on app approval; until then flows are tested with unit tests and the AppLink mock server.
- The detection test set is small; precision/recall numbers are in the proposal PDF.
- No LLM fallback is enabled in this version (interface only; would receive redacted text only).
- Charging: standard AppLink SMS charges apply; Family Guard is Tk 30/month.

## Prior work declaration

The Flutter app scaffold and project tooling were reused from our earlier PlantPal project. All ScamShield logic is new for this competition.

## AI-use and third-party services declaration

- AI tools: Claude (Anthropic) helped write code, content and documentation; all output was reviewed by the team.
- Third-party services: Banglalink AppLink (SMS, OTP, Subscription, CaaS), Vercel (HTTPS callbacks).
- The Applink-as-a-Skill files are proprietary and are **not** part of this repo.
- Test data: real SMS have names and numbers removed; sources are documented with the dataset.