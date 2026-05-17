# Product Requirements Document (PRD)
## Atmos — Private Messaging App for Couples

| Field | Detail |
|---|---|
| Product Name | Atmos |
| Version | 1.0.0 |
| Platform | Flutter (iOS + Android) |
| Author | Product Team |
| Status | Draft |
| Last Updated | May 2026 |

---

## 1. Executive Summary

Atmos is a private, secure mobile application designed exclusively for two people in a romantic relationship. Unlike general messaging apps, Atmos is purpose-built for couples — combining encrypted chat, disappearing snaps, synchronized music listening, shared games, and a couple's notepad into one intimate space.

The app is built with Flutter on the client and a self-hosted Node/Express API backed by PostgreSQL, using the YouTube Data API for music search/playback (key in `.env` as `YOUTUBE_API_KEY`) and optional FCM for push notifications.

---

## 2. Problem Statement

Couples today communicate across fragmented platforms — texting on WhatsApp, sharing moments on Instagram, playing games on separate apps, and listening to music individually. There is no single private space designed to nurture a couple's relationship digitally.

Existing apps either lack privacy (social networks), lack intimacy features (generic messengers), or cost money (Between, Couple app). Atmos solves this by being private, encrypted, and feature-rich for the specific context of two people in love.

---

## 3. Goals & Success Metrics

### Product Goals
- Provide a single private space for couples to communicate, play, and share
- Ensure all messages are end-to-end encrypted and server-unreadable
- Deliver a polished, delightful UI comparable to consumer social apps
- Keep infrastructure cost low using PostgreSQL on a small VPS or local deployment

### Success Metrics (6 months post-launch)

| Metric | Target |
|---|---|
| Installs | 5,000+ |
| DAU / MAU ratio | ≥ 55% (high retention) |
| Average session length | ≥ 8 minutes |
| D7 retention | ≥ 60% |
| Crash-free rate | ≥ 99.2% |
| App Store / Play Store rating | ≥ 4.5 stars |
| Messages sent per couple per day | ≥ 30 |
| Games played per couple per week | ≥ 3 |

---

## 4. Target Users

### Primary Persona — Long-Distance Couples
- Age: 18–32
- Situation: In a relationship with physical distance (different cities, countries)
- Pain point: Wants to feel close despite distance; current apps feel generic
- Jobs to be done: Stay connected daily, share moments, have fun together remotely

### Secondary Persona — Nearby Couples Who Want a Private Space
- Age: 20–35
- Situation: Cohabitating or nearby but wants a dedicated relationship app
- Pain point: Relationship content gets mixed with friend groups on WhatsApp/Instagram
- Jobs to be done: Have a dedicated couple space, track memories, share routine

---

## 5. Scope

### In Scope — v1.0
- Encrypted one-on-one chat with themes
- Snaps (disappearing photos/videos)
- Listen Together (YouTube Data API)
- 6 built-in games (Chess, Tic Tac Toe, Truth or Dare, Word Puzzle, Love Quiz, Memory Cards)
- Shared Notes & Routine Updates
- Profile setup & couple linking
- Push notifications (FCM)
- App lock (biometric/PIN)
- Light / Dark mode

### Out of Scope — v1.0 (future versions)
- Group chats or adding more than 2 users
- In-app purchases or subscription tiers
- Video calling (may use Jitsi free tier in v1.1)
- AI-generated relationship suggestions
- Web app version
- Shared photo album / timeline

---

## 6. Functional Requirements

### 6.1 Authentication

| ID | Requirement | Priority |
|---|---|---|
| AUTH-01 | Users must sign up with email & password or Google Sign-In via API (JWT sessions stored in PostgreSQL) | Must Have |
| AUTH-02 | Email verification required before accessing the app | Must Have |
| AUTH-03 | Password reset via email link | Must Have |
| AUTH-04 | Session persists across app restarts (auto sign-in) | Must Have |
| AUTH-05 | Biometric / PIN lock on app open (optional, user-controlled) | Should Have |

### 6.2 Couple Linking

| ID | Requirement | Priority |
|---|---|---|
| LINK-01 | Newly registered user can generate a unique 6-digit pairing code | Must Have |
| LINK-02 | Partner enters code to send a link request | Must Have |
| LINK-03 | Original user receives push notification to confirm or reject link | Must Have |
| LINK-04 | Once linked, the bond is stored in PostgreSQL and both users see each other's profile | Must Have |
| LINK-05 | Either user can unlink via Settings (requires confirmation from both) | Should Have |
| LINK-06 | A user cannot be linked to more than one partner simultaneously | Must Have |

### 6.3 Chat

| ID | Requirement | Priority |
|---|---|---|
| CHAT-01 | Real-time message delivery via WebSocket + PostgreSQL | Must Have |
| CHAT-02 | Messages encrypted AES-256 client-side before write to PostgreSQL | Must Have |
| CHAT-03 | Delivery status per message (Sent / Delivered / Read) | Must Have |
| CHAT-04 | Partner typing indicator via WebSocket presence | Must Have |
| CHAT-05 | Image and voice note sending (encrypted upload to API media storage) | Must Have |
| CHAT-06 | Message reply (quote + content) | Should Have |
| CHAT-07 | Message reactions (emoji picker, long press) | Should Have |
| CHAT-08 | Delete message for self or both | Should Have |
| CHAT-09 | Chat theme selection (8 themes, synced to partner) | Should Have |
| CHAT-10 | GIF search and sending via Giphy API | Could Have |
| CHAT-11 | Full-text search within message history (client-side on cached Hive data) | Could Have |

### 6.4 Snaps

| ID | Requirement | Priority |
|---|---|---|
| SNAP-01 | In-app camera for photo and video (up to 15s) capture | Must Have |
| SNAP-02 | Snap uploaded encrypted to API media storage (path in PostgreSQL) | Must Have |
| SNAP-03 | View timer configurable by sender (1s / 3s / 5s / 10s / No Limit) | Must Have |
| SNAP-04 | Snap file deleted from server by scheduled API job after timer | Must Have |
| SNAP-05 | Screenshot detection — partner notified if screenshot is taken | Must Have |
| SNAP-06 | Text overlay and doodle drawing tools on snap | Should Have |
| SNAP-07 | Snap sticker pack (12 stickers minimum) | Could Have |
| SNAP-08 | Local Memories save (device-only, no server) | Could Have |

### 6.5 Listen Together

| ID | Requirement | Priority |
|---|---|---|
| MUSIC-01 | Track search via YouTube Data API (`YOUTUBE_API_KEY` in server `.env`) | Must Have |
| MUSIC-02 | Video/audio playback via YouTube embed or stream URL using `just_audio` | Must Have |
| MUSIC-03 | Play/Pause/Seek state written to PostgreSQL and synced to partner via WebSocket | Must Have |
| MUSIC-04 | "Both listening" presence indicator | Must Have |
| MUSIC-05 | Shared queue persisted in PostgreSQL | Must Have |
| MUSIC-06 | Save favourite YouTube tracks to couple profile | Could Have |
| MUSIC-07 | Save queue as named couple playlist (max 5) | Should Have |
| MUSIC-08 | Playback history (last 50 tracks) | Could Have |

### 6.6 Games

| ID | Requirement | Priority |
|---|---|---|
| GAME-01 | Chess with move sync via WebSocket + PostgreSQL | Must Have |
| GAME-02 | Tic Tac Toe with best-of-5 mode | Must Have |
| GAME-03 | Truth or Dare with 200+ couple questions | Must Have |
| GAME-04 | Love Quiz (10 questions per round) | Must Have |
| GAME-05 | Word Puzzle (co-op, daily grid) | Should Have |
| GAME-06 | Memory Cards with custom photo deck option | Should Have |
| GAME-07 | Couple score/streak tracker across all games | Should Have |
| GAME-08 | In-game chat bubble (send emoji reactions during game) | Could Have |

### 6.7 Notes

| ID | Requirement | Priority |
|---|---|---|
| NOTE-01 | Create note with type tag (Routine / Reminder / Love Note / Plan) | Must Have |
| NOTE-02 | Rich text formatting (bold, italic, bullet) | Must Have |
| NOTE-03 | Notes stored in PostgreSQL, visible to both partners in real time | Must Have |
| NOTE-04 | FCM push notification for new note from partner | Must Have |
| NOTE-05 | Due date / reminder on notes | Should Have |
| NOTE-06 | Pin up to 3 notes | Should Have |
| NOTE-07 | React to notes (heart / emoji) | Should Have |
| NOTE-08 | Auto-archive notes older than 90 days | Could Have |
| NOTE-09 | Export notes as PDF | Could Have |

### 6.8 Profile & Settings

| ID | Requirement | Priority |
|---|---|---|
| PROF-01 | Profile photo upload (API media storage, compressed) | Must Have |
| PROF-02 | Display name, bio, status message | Must Have |
| PROF-03 | Anniversary date field with days-together counter | Must Have |
| PROF-04 | Couple stats dashboard (messages, snaps, days) | Should Have |
| PROF-05 | Light / Dark / System theme toggle | Must Have |
| PROF-06 | Notification preferences per feature with quiet hours | Should Have |
| PROF-07 | Account deletion with full PostgreSQL + media storage purge | Must Have |
| PROF-08 | Privacy: incognito mode (hide online status) | Should Have |

---

## 7. Non-Functional Requirements

### 7.1 Performance
- App cold start time: < 2.5 seconds on mid-range Android (Snapdragon 680 class)
- Message delivery latency: < 500ms on 4G connection
- Image upload (2MB photo): < 4 seconds on 4G
- Music sync offset between partners: < 200ms
- Game move sync latency: < 300ms

### 7.2 Security
- All messages encrypted AES-256 client-side; keys never leave the device
- Keys stored in flutter_secure_storage (uses Android Keystore / iOS Keychain)
- API authorization middleware enforces that only linked partners can read each other's data
- HTTPS enforced for all API connections
- Screenshot blocking enabled by default (can be disabled in Settings)

### 7.3 Offline Behaviour
- Last 500 messages cached in Hive for offline reading
- Notes readable offline via Hive cache
- Queue and profile readable offline
- All write operations queued and synced on reconnect (local Hive cache + API retry queue)

### 7.4 Accessibility
- Minimum touch target size: 48×48dp (Material Design)
- Dynamic font size support (respects OS accessibility font scale)
- Sufficient color contrast (WCAG AA for text on backgrounds)
- Screen reader labels on all interactive elements

### 7.5 Compatibility
- Minimum iOS: 14.0
- Minimum Android: API 23 (Android 6.0)
- Tested on screen sizes: 5.0" to 6.9"
- Tablet layout: responsive but optimized for phones

---

## 8. PostgreSQL Resource Estimate (Per Couple Per Day)

| Resource | Estimated Usage | Notes |
|---|---|---|
| DB reads/writes | ~2,500 queries | Indexed by `couple_id`; low for 2-user apps |
| Media storage | ~10 MB/day | Encrypted files on disk/S3; metadata in PostgreSQL |
| WebSocket messages | ~500 events | Chat, typing, music, games |
| Push notifications (FCM) | ~20 | Optional; unlimited on FCM free tier |
| Auth operations | ~5 | JWT issue/refresh; users table in PostgreSQL |

*Atmos stays lightweight on a single PostgreSQL instance for hundreds of active couples.*

---

## 9. Flutter Packages (All Free / Open Source)

| Package | Version | Purpose |
|---|---|---|
| `dio` | latest | REST API client |
| `web_socket_channel` | latest | Realtime sync (chat, music, games) |
| `flutter_secure_storage` | latest | Encryption key + JWT storage |
| `encrypt` | latest | AES-256 encryption |
| `riverpod` | latest | State management |
| `hive_flutter` | latest | Local offline cache |
| `just_audio` | latest | Music playback |
| `flutter_chess_board` | latest | Chess UI + logic |
| `camera` | latest | Snap camera |
| `image_picker` | latest | Gallery access |
| `flutter_sound` | latest | Voice note recording |
| `local_auth` | latest | Biometric / PIN lock |
| `go_router` | latest | Navigation |
| `cached_network_image` | latest | Efficient image loading |
| `flutter_animate` | latest | UI animations |
| `pdf` | latest | Note PDF export |
| `http` | latest | YouTube Data API proxy calls |
| `intl` | latest | Date/time formatting |
| `firebase_messaging` | latest | Push notifications (optional) |

---

## 10. System Architecture

```
┌─────────────────────────────────────────────┐
│              Flutter App (Client)            │
│  ┌──────────┐ ┌──────────┐ ┌─────────────┐  │
│  │  Chat UI │ │ Games UI │ │  Music UI   │  │
│  └────┬─────┘ └────┬─────┘ └──────┬──────┘  │
│       │             │              │          │
│  ┌────▼─────────────▼──────────────▼──────┐  │
│  │         Riverpod State Layer            │  │
│  └────────────────┬────────────────────────┘  │
│                   │                            │
│  ┌────────────────▼────────────────────────┐  │
│  │  AES-256 Encrypt/Decrypt (client-side)  │  │
│  └────────────────┬────────────────────────┘  │
└───────────────────┼────────────────────────────┘
                    │ HTTPS
┌───────────────────▼────────────────────────────┐
│         Node/Express API + PostgreSQL          │
│  ┌──────────────┐  ┌───────────────────────┐   │
│  │  PostgreSQL  │  │  WebSocket Server     │   │
│  │  (users,     │  │  (chat, music sync,   │   │
│  │   couples,   │  │   games, presence)    │   │
│  │   messages,  │  │                       │   │
│  │   notes)     │  │                       │   │
│  └──────────────┘  └───────────────────────┘   │
│  ┌──────────────┐  ┌───────────────────────┐   │
│  │  Media Store │  │  Background Jobs      │   │
│  │  (encrypted  │  │  (snap deletion,      │   │
│  │   snaps,     │  │   retention purge)    │   │
│  │   profiles)  │  │                       │   │
│  └──────────────┘  └───────────────────────┘   │
│  ┌──────────────┐  ┌───────────────────────┐   │
│  │  JWT Auth    │  │  FCM (optional)       │   │
│  │  (email,     │  │  (push notifications) │   │
│  │   Google)    │  │                       │   │
│  └──────────────┘  └───────────────────────┘   │
└────────────────────────────────────────────────┘
                    │
┌───────────────────▼───────────────┐
│       External Free APIs          │
│  YouTube Data API (music search)  │
│  Giphy API (GIF search)           │
└───────────────────────────────────┘
```

---

## 11. PostgreSQL Data Model

```sql
-- users
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  display_name  TEXT,
  photo_url     TEXT,
  bio           TEXT,
  status        TEXT,
  partner_id    UUID REFERENCES users(id),
  couple_id     UUID REFERENCES couples(id),
  anniversary_date TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- couples
CREATE TABLE couples (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_ids   UUID[] NOT NULL CHECK (array_length(user_ids, 1) = 2),
  theme      TEXT DEFAULT 'rose',
  nickname   TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- messages (ciphertext only)
CREATE TABLE messages (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id         UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
  encrypted_content TEXT NOT NULL,
  iv                TEXT NOT NULL,
  type              TEXT CHECK (type IN ('text','image','voice','gif')),
  sender_id         UUID NOT NULL REFERENCES users(id),
  status            TEXT CHECK (status IN ('sent','delivered','read')),
  reply_to          UUID REFERENCES messages(id),
  created_at        TIMESTAMPTZ DEFAULT now()
);

-- snaps
CREATE TABLE snaps (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id   UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
  storage_ref TEXT NOT NULL,
  sender_id   UUID NOT NULL REFERENCES users(id),
  duration    INT,
  viewed      BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now(),
  expires_at  TIMESTAMPTZ
);

-- notes
CREATE TABLE notes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id  UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  type       TEXT CHECK (type IN ('routine','reminder','love','plan')),
  author_id  UUID NOT NULL REFERENCES users(id),
  pinned     BOOLEAN DEFAULT false,
  due_date   TIMESTAMPTZ,
  reactions  JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- game_state
CREATE TABLE game_state (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id    UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
  game         TEXT NOT NULL,
  state        JSONB NOT NULL,
  current_turn UUID REFERENCES users(id),
  scores       JSONB DEFAULT '{}',
  updated_at   TIMESTAMPTZ DEFAULT now()
);

-- music_session (one row per couple)
CREATE TABLE music_sessions (
  couple_id    UUID PRIMARY KEY REFERENCES couples(id) ON DELETE CASCADE,
  track_id     TEXT,
  track_title  TEXT,
  track_artist TEXT,
  is_playing   BOOLEAN DEFAULT false,
  position     NUMERIC DEFAULT 0,
  updated_at   TIMESTAMPTZ DEFAULT now(),
  updated_by   UUID REFERENCES users(id),
  queue        JSONB DEFAULT '[]'
);
```

---

## 12. API Authorization (Summary)

- All routes require a valid JWT; `userId` is taken from the token.
- Couple-scoped routes verify `request.user.id` is in `couples.user_ids` for the requested `couple_id`.
- Users may only update their own row in `users`.
- Media downloads require the same couple membership check against `storage_ref` path prefix.
- Row-level security is enforced in application middleware, not client-side.

---

## 13. Release Plan

### Phase 1 — MVP (Weeks 1–8)
- Auth + couple linking
- Encrypted text chat
- Basic profile setup
- Push notifications
- Chess game

### Phase 2 — Core Features (Weeks 9–16)
- Snaps (photo + video)
- Chat themes + media messages
- Listen Together (YouTube)
- Notes feature
- Tic Tac Toe + Truth or Dare

### Phase 3 — Polish & Remaining Games (Weeks 17–22)
- Love Quiz + Word Puzzle + Memory Cards
- App lock (biometric)
- Chat GIFs, reactions, reply
- Couple stats dashboard
- Performance optimization + crash fixes

### Phase 4 — Launch (Week 23–24)
- App Store + Play Store submission
- Beta testing with 50 real couples
- Crash-free rate validation
- App Store assets + screenshots

---

## 14. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| PostgreSQL load at scale | Medium | High | Add connection pooling, indexes on `couple_id`, read replicas, and pagination |
| YouTube Data API quota exceeded | Medium | Medium | Cache search results in Hive; debounce search; server-side quota monitoring |
| AES key loss = permanent message loss | Low | High | Document clearly; consider key backup via partner agreement |
| Flutter platform divergence (iOS vs Android) | Medium | Medium | Test on both platforms from day one; use platform channels only when necessary |
| App Store rejection for disappearing content | Low | Medium | Ensure snap feature complies with App Store guidelines 1.1.3 |
| Screenshot detection unreliable on iOS | High | Low | Notify partner of attempt; cannot technically block screenshots on iOS |

---

## 15. Open Questions

1. Should the app support more than 2 linked users (e.g., throuple relationships)? → Deferred to v2.
2. What happens to data if one partner deletes their account? → Current answer: the couple channel remains read-only for 30 days, then purged.
3. Should there be a "break" mode where syncing pauses without full unlink? → Consider for v1.1.
4. Should we store encrypted backups of chat history to device? → Evaluate iCloud/Google Drive integration for v1.1.

---

*This PRD is a living document. Update version and date fields on each revision.*