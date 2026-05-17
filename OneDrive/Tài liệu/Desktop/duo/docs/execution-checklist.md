# Atmos Execution Checklist (PRD-aligned)

**Stack:** Flutter (iOS + Android) · Node/Express API · PostgreSQL · WebSockets · YouTube Data API

**Status legend:** [x] Done · [-] In progress · [ ] Not started

---

## Phase 0 — Project Setup

### Documentation & decisions
- [x] PRD, features, frontend, wireframe docs finalized
- [x] App named **Atmos** across docs
- [x] Backend: PostgreSQL (not Firebase)
- [x] Music: YouTube Data API (`YOUTUBE_API_KEY` in `.env`)
- [x] Client: **Flutter** (confirmed; replaces React/Vite plan)
- [x] `.env` / `.env.example` configured
- [x] PostgreSQL database `atmos` created

### Scaffolding
- [x] Node/Express API scaffolded (`server/`)
- [x] PostgreSQL migrations applied (schema from PRD §11)
- [x] API health check + DB connection verified
- [x] Flutter project scaffolded (`flutter create`)
- [x] Flutter folder layout per [frontend.md](frontend.md) §11 (`lib/core`, `lib/features`, `lib/shared`)
- [x] Design tokens (`app_colors`, `app_theme`, Syne + DM Sans)
- [x] GoRouter setup (splash, onboarding, home shell)
- [x] Splash + onboarding shells
- [x] Home shell + bottom nav (5 tabs)
- [x] Flutter wired to API (`--dart-define=API_BASE_URL=...`)

---

## Current Sprint

- [x] Scaffold Node/Express API + PostgreSQL migrations (PRD §11 schema)
- [x] Scaffold Flutter app
- [x] Wire Flutter to API (base URL via dart-define)
- [x] M1: Auth + couple link + encrypted chat end-to-end

---

## Phase 1 — MVP (Weeks 1–8)

PRD §13: Auth, couple linking, encrypted chat, profile, push notifications, chess.

### Backend
- [x] JWT auth (signup, login, `/me`; refresh deferred)
- [-] Email verification (optional for v0 - skipped)
- [x] Couple linking (6-char code + partner confirm)
- [x] Messages API (ciphertext + IV only in PostgreSQL)
- [x] WebSocket: real-time messages + typing indicator (MVP stubs)
- [x] Authorization middleware (couple-scoped access)
- [x] Media upload endpoint (encrypted photos; path in DB)

### Flutter
- [x] Design tokens: `app_colors.dart`, `app_theme.dart`, Syne + DM Sans ([frontend.md](frontend.md) §2)
- [x] GoRouter setup ([frontend.md](frontend.md) §4)
- [x] Splash screen + auth state check (JWT in secure storage → home or onboarding)
- [x] Onboarding: signup, login wired to API (Google Sign-In UI placeholder)
- [x] Profile setup screen
- [x] Couple link screen (generate / enter code shell)
- [x] Chat screen: message list, input bar, bubbles (UI shell; no API)
- [x] Client-side AES-256 encryption before send
- [x] Delivery / read receipts
- [x] Basic profile screen (name, photo, anniversary) (UI shell)
- [x] Chess screen (`flutter_chess_board` + WebSocket sync)

### Infrastructure
- [x] FCM push notifications (`firebase_messaging` — push only)
- [x] Hive offline cache for last 500 messages

---

## Phase 2 — Core Features (Weeks 9–16)

PRD §13: Snaps, chat themes + media, Listen Together (YouTube), notes, Tic Tac Toe + Truth or Dare.

### Backend
- [x] Snaps API + encrypted storage + expiry job
- [x] Snap view events + partner notification
- [x] Notes CRUD + real-time sync
- [x] Game state API (chess, tic-tac-toe, truth or dare)
- [x] Music session + queue (PostgreSQL)
- [x] YouTube search proxy (`YOUTUBE_API_KEY` server-side)

### Flutter
- [x] Snap camera screen (`camera` package)
- [x] Snap view screen (timed, hold-to-pause)
- [x] Snaps tab (grid, unseen indicators)
- [x] Chat themes bar (8 themes, synced to partner)
- [x] Image + voice note messages
- [x] Together screen: music player + games hub
- [x] YouTube search + synced playback UI
- [x] Notes screen + compose screen
- [x] Tic Tac Toe + Truth or Dare screens
- [x] Screenshot detection alerts (platform-dependent)

---

## Phase 3 — Polish (Weeks 17–22)

PRD §13: Remaining games, app lock, GIFs/reactions/reply, couple stats, performance.

### Backend
- [x] Love Quiz, Word Puzzle, Memory Cards game state
- [x] GIF proxy (Giphy API) — optional
- [x] Couple stats aggregation endpoint
- [x] Account deletion + full data purge

### Flutter
- [x] Love Quiz, Word Puzzle, Memory Cards screens
- [x] App lock: PIN + biometric (`local_auth`)
- [x] Message reactions, reply, delete for both
- [x] GIF picker (Giphy)
- [x] Couple stats dashboard on profile
- [x] Light / dark / system theme
- [x] Performance pass (cold start, message latency)
- [x] Accessibility pass (48dp targets, semantics, font scale)

---

## Phase 4 — Launch (Weeks 23–24)

PRD §13: Store submission, beta, security audit.

- [ ] iOS build + App Store Connect setup
- [ ] Android release build + Play Console setup
- [ ] App icons, screenshots, store copy
- [ ] Beta test with 50 couples
- [ ] Security audit per [security-audit.md](security-audit.md)
- [ ] Crash-free rate ≥ 99.2%
- [ ] Production deployment (API + PostgreSQL hosted, HTTPS)
- [ ] Rate limiting on public API

---

## Key Flutter Packages (from PRD §9)

| Package | Purpose |
|---------|---------|
| `dio` | REST API client |
| `web_socket_channel` | Realtime sync |
| `riverpod` | State management |
| `go_router` | Navigation |
| `encrypt` + `flutter_secure_storage` | E2EE + JWT storage |
| `hive_flutter` | Offline cache |
| `just_audio` | Music playback |
| `flutter_chess_board` | Chess UI |
| `camera` / `image_picker` | Snaps + media |
| `flutter_animate` | UI animations |
| `google_fonts` | Syne + DM Sans |
| `firebase_messaging` | Push notifications (optional) |
