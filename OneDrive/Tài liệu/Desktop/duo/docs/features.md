# Atmos — Feature Specification

> A private, secure messaging app built exclusively for couples, built with Flutter using free and open-source tools.

---

## Tech Stack (All Free)

| Layer | Tool | Purpose |
|---|---|---|
| Frontend | Flutter (Dart) | Cross-platform iOS & Android UI |
| Backend | Node/Express API | REST + WebSocket endpoints |
| Database | PostgreSQL | Users, couples, messages, notes, game state |
| Realtime | WebSockets | Live sync for chat, music, games, presence |
| Auth | JWT + PostgreSQL | Email/password + Google Sign-In |
| Media Storage | API file store (disk/S3) | Encrypted snaps, profile pictures (paths in PostgreSQL) |
| Notifications | Firebase Cloud Messaging (FCM) | Push notifications (optional) |
| Music API | YouTube Data API | Track search, thumbnails, playback (`YOUTUBE_API_KEY` in `.env`) |
| Chess Engine | flutter_chess_board (pub.dev) | Offline + online chess logic |
| Encryption | flutter_secure_storage + AES | End-to-end message encryption |
| State Mgmt | Riverpod | App-wide reactive state |
| Local DB | Hive (NoSQL) | Offline caching |
| CI/CD | Codemagic free tier | Build & deploy pipeline |

---

## Feature 1 — Secure Encrypted Chat

### Overview
A private one-on-one chat channel between two linked partners. All messages are encrypted end-to-end using AES-256 before being stored in PostgreSQL.

### Sub-features

**1.1 Text Messaging**
- Send and receive real-time text messages
- Message delivery status: Sent → Delivered → Read (double tick)
- Message reactions (long press to react with emoji)
- Reply to specific messages with quoted preview
- Delete message for self or both users
- Message search within conversation history

**1.2 Chat Themes**
- 8 preset gradient color themes (Rose, Plum, Ocean, Forest, Gold, Candy, Midnight, Blush)
- Theme applies to own message bubbles and header
- Theme syncs to partner's device in real time
- Custom background image upload (from gallery)

**1.3 Media Messaging**
- Send images from camera or gallery (compressed before upload)
- Send short voice notes (up to 60 seconds)
- Send GIFs via Giphy free API integration
- Auto-delete media from server after 30 days (configurable)

**1.4 Message Encryption**
- AES-256 encryption applied client-side before sending
- Encryption keys stored in flutter_secure_storage (never leaves device)
- Server only stores ciphertext — the API cannot read messages

---

## Feature 2 — Snaps (Disappearing Photos & Videos)

### Overview
Send photos or short videos that auto-delete after being viewed, similar to Snapchat. Encrypted files are stored on the API media store; metadata and expiry live in PostgreSQL. A background job purges files after the view timer.

### Sub-features

**2.1 Sending Snaps**
- Capture photo or record video (up to 15 seconds) in-app
- Apply text overlays, stickers, or doodle drawing before sending
- Set view timer: 1s / 3s / 5s / 10s / No Limit
- Snap is uploaded encrypted to API media storage

**2.2 Receiving Snaps**
- Tap-to-view interaction; timer starts on open
- Snap is deleted from server immediately after timer expires
- Screenshot detection — partner is notified if a screenshot is taken
- Unseen snaps show bold indicator in sidebar

**2.3 Snap Archive (Optional)**
- User can choose to save a snap to their private "Memories" section before it expires
- Memories are stored locally on device only (not server)

---

## Feature 3 — Instagram-Style Chat Customization

### Overview
Rich profile and chat personalization so the app feels personal and unique to each couple.

### Sub-features

**3.1 Profile Setup**
- Upload profile photo (API media storage)
- Set display name and bio
- Set "couple anniversary date" — shown as days counter in sidebar
- Choose avatar frame / border style (10 options)
- Set status message (emoji + text, max 60 chars)

**3.2 Couple Linking**
- Generate a unique 6-digit invite code
- Partner enters code to link accounts
- Once linked, both accounts are permanently paired (can be unlinked in settings)
- Couple nickname (e.g., "Alex & Sophia ♡") shown in app header

**3.3 Chat Customization**
- Chat bubble shape: Rounded / Square / Tail
- Font size: Small / Medium / Large
- Own vs partner bubble color independently configurable
- Emoji skin tone preference
- Message timestamp style: Relative ("2 min ago") or Absolute ("8:14 AM")

---

## Feature 4 — Listen Together (Shared Music)

### Overview
Both partners listen to the same music in perfect sync using the YouTube Data API. The API key is stored server-side in `.env` as `YOUTUBE_API_KEY`; the client searches and plays tracks through the Atmos API proxy.

### Sub-features

**4.1 Music Player**
- Browse and search tracks via YouTube Data API (proxied through the API server)
- Playback via YouTube video/audio stream
- Thumbnail, title, and channel name from YouTube metadata
- Album art, track name, artist displayed

**4.2 Sync Playback**
- Play/Pause/Seek actions sync to partner's device via WebSocket + PostgreSQL
- Latency compensation using server timestamp delta
- "Both listening" indicator with animated waveform
- Partner disconnect shown with gentle toast notification

**4.3 Shared Queue**
- Either partner can add tracks to the shared queue
- Drag to reorder queue
- Queue persists in PostgreSQL between sessions
- "Now Playing" history (last 50 tracks)

**4.4 Couple Playlist**
- Save queue as a named couple playlist
- Max 5 saved playlists
- Share playlist link (deep link into app)

---

## Feature 5 — Play Games Together

### Overview
Built-in multiplayer games played in real time over WebSockets. Game state is persisted in PostgreSQL.

### Sub-feature 5.1 — Chess
- Full chess board using `flutter_chess_board` package
- Moves synced via WebSocket + PostgreSQL
- Game timer: Untimed / 5 min / 10 min blitz
- Move history panel with undo request (both must agree)
- Win / Draw / Resign detection
- Simple ELO-style couple score tracker

### Sub-feature 5.2 — Tic Tac Toe
- Classic 3×3 grid, first to 3 in a row wins
- Best-of-5 mode with running score
- Animated win line highlight

### Sub-feature 5.3 — Truth or Dare (Couples Edition)
- 200+ curated couple-specific question deck
- Categories: Romantic / Fun / Deep / Spicy (Spicy locked unless both users enable)
- Add custom questions to personal deck
- Skip limit: 3 skips per session

### Sub-feature 5.4 — Word Puzzle (Co-op)
- Shared 5×5 letter grid
- Both partners see each other's cursor in real time
- Score accumulates together — cooperative, not competitive
- Daily puzzle (new grid every midnight UTC)

### Sub-feature 5.5 — Love Quiz
- 10 questions per round about each other ("What's my favourite movie?")
- Each partner answers independently, then results compared
- Score = number of matched answers
- Streak counter across rounds

### Sub-feature 5.6 — Memory Cards
- Flip-and-match card pairs
- Default deck uses emoji; custom deck can use couple's own photos
- Cooperative (find all pairs together) or competitive (who finds more)
- Best time leaderboard (local, between couple only)

---

## Feature 6 — Shared Notes & Routine Updates

### Overview
A shared digital notepad where both partners can post routine updates, reminders, love notes, or plans. Think of it as a private couple journal.

### Sub-features

**6.1 Note Creation**
- Rich text editor (bold, italic, bullet lists)
- Note types: Routine Update / Reminder / Love Note / Plan / Random
- Optional due date / time for reminders (triggers FCM push notification)
- Emoji picker for expressive notes
- Max 1000 characters per note

**6.2 Note Feed**
- Chronological feed of all notes from both partners
- Filter by author or note type
- Pinned notes section at top (max 3 pinned notes)
- Partner typing indicator when they're composing a note

**6.3 Reactions & Replies**
- React to a note with a heart or emoji
- Reply inline (threaded)
- Mark note as "Done" (for reminders) — strikethrough style

**6.4 Note Archive**
- Notes older than 90 days auto-archived (still accessible via Archive tab)
- Export notes to PDF (using `pdf` Flutter package)

---

## Feature 7 — Profile & Settings

### Sub-features

**7.1 Profile**
- Profile photo, display name, bio, status
- Couple stats: Days together, total messages, snaps sent, games played
- Favourite song (linked from Listen Together)

**7.2 Privacy & Security**
- App lock: PIN / Biometric (Face ID / Fingerprint)
- Incognito mode: hide online status from partner temporarily
- Block screenshots globally (Android: FLAG_SECURE; iOS: overlay approach)
- Account deletion with data purge (GDPR compliant)

**7.3 Notifications**
- Granular controls per feature (chat, snaps, notes, games)
- Quiet hours (DND schedule)
- Custom notification sound

**7.4 Appearance**
- Light / Dark / System theme
- Accent color picker
- Font size global override

---

## Feature 8 — Onboarding & Couple Linking Flow

1. Splash screen with animated logo
2. Sign up with email or Google
3. Set up profile (name, photo, bio)
4. Choose: Create couple link OR Enter partner's code
5. Partner receives push notification + in-app prompt to confirm link
6. Both land on home screen together (synchronized welcome animation)

---

## Permissions Required

| Permission | Reason |
|---|---|
| Camera | Snaps, profile photo |
| Microphone | Voice notes |
| Storage / Photos | Media messages, snap memories |
| Notifications | FCM push notifications |
| Biometrics | App lock feature |
| Internet | All network features |

---

*Atmos is designed for low-traffic couple use: two users per channel, indexed PostgreSQL queries, and encrypted media on disk keep a single database instance sufficient for hundreds of active couples.*
