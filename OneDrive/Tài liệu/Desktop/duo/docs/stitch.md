# Atmos — Stitch UI Design Prompt

## App Identity

Design the UI for **Atmos**, a private encrypted messaging app built exclusively for couples. The app should feel like a personal, intimate sanctuary — warm, modern, and slightly playful without being childish. Think of the aesthetic as **"luxury dark romance meets soft glassmorphism"** — deep, rich backgrounds with soft glowing accents, translucent cards, smooth micro-animations, and a palette that feels cosy and private, like candlelight on a dark evening.

---

## Design Language

**Aesthetic Direction:** Soft dark luxury — deep navy/charcoal backgrounds, warm rose-gold and blush accent colors, frosted glass cards, smooth gradients, and delicate glow effects. Not cold or techy. Warm, intimate, personal.

**Color Palette:**
- Background: `#0D0D1A` (deep midnight navy)
- Surface / Cards: `#1A1A2E` with 60% opacity frosted glass (`backdrop-filter: blur`)
- Primary Accent: `#E8758A` (rose pink)
- Secondary Accent: `#F4A261` (warm peach/gold)
- Text Primary: `#F0EAE2` (warm off-white)
- Text Secondary: `#8E8BA0` (muted lavender-grey)
- Success/Online: `#6FCF97`
- Danger/Alert: `#EB5757`

**Typography:**
- Display / Headings: `Playfair Display` (elegant serif — gives warmth and romance)
- Body / UI: `DM Sans` (clean, modern, readable)
- Accent labels: `DM Mono` (for timestamps, counters, codes)

**Motion:**
- Smooth spring transitions on navigation (350ms ease-in-out)
- Message bubbles slide in from bottom with a gentle fade
- Snaps open with a slow iris-bloom reveal animation
- Bottom tab bar icons pulse softly on select
- All modals enter from bottom sheet style (slide-up)

**Shape Language:**
- Cards: `border-radius: 20px`
- Buttons: `border-radius: 14px`
- Message bubbles: `border-radius: 18px 18px 4px 18px` (sent) / `18px 18px 18px 4px` (received)
- Avatars: Fully circular with a soft glowing ring in the accent color when online

---

## Screens to Design

### 1. Splash / Onboarding Screen
- Full-screen deep navy background with a soft animated gradient mesh in rose and peach
- App logo centered: a simple abstract icon of two interlocking rings or a lock-heart hybrid
- Tagline below logo: *"Your private world, just the two of you."*
- Two buttons: **Sign Up** (filled rose) and **Log In** (ghost/outlined)
- Subtle animated floating particles or soft bokeh in the background

### 2. Sign Up / Log In Screen
- Clean card centered on screen with frosted glass effect
- Fields: Email, Password (with show/hide toggle), Confirm Password (sign up only)
- Email verification state: shows a confirmation illustration with "Check your inbox" message
- Social auth: none — email only
- Link between Sign Up ↔ Log In at the bottom
- Subtle divider and minimal branding at top

### 3. Partner Link Screen (Post Sign-Up)
- Shown once after email verification
- Headline: *"Find your person"*
- Two options side by side:
  - **Share your code** — displays a large, copyable 6-character invite code with a copy + share button
  - **Enter a code** — text input for partner's invite code
- Animated heart or link-chain icon between the two options
- Progress indicator at top (Step 2 of 2)

### 4. Home / Chat Screen
- Top bar: App logo left, notification bell right
- Single large chat card (since it's only 1:1) showing:
  - Partner's avatar (circular, glow ring if online)
  - Partner's name (display + nickname)
  - Last message preview (truncated, encrypted indicator icon)
  - Timestamp
  - Unread badge
- Below chat card: Quick access row — icons for Notes, Games, Music, Snaps
- Days-together counter subtly shown below partner name: *"❤️ 247 days together"*
- Bottom navigation bar: Home, Chat, Games, Music, Profile

### 5. Chat Screen (Conversation)
- Full-screen chat with translucent themed wallpaper behind messages
- Top bar: Back arrow, partner avatar + name, video/call icon placeholder (greyed out V2), info icon
- Message bubbles:
  - Sent: rose-pink gradient, right-aligned, rounded with sharp bottom-right corner
  - Received: frosted glass card, left-aligned, sharp bottom-left corner
  - Timestamps below each bubble in muted small text
  - Encrypted lock icon on each bubble (subtle, top-right of bubble)
- Input bar at bottom:
  - Left icons: Camera (snap), Attachment (file), Gallery (photo)
  - Center: text field with placeholder *"Say something..."*
  - Right: Send button (rose, animated on press)
- Snap preview: tapping camera opens a full-screen camera with a circular shutter button and a timer selector (1s–10s)

### 6. Snap View Screen
- Full-screen dark overlay when a snap is open
- Content fills screen
- Circular countdown ring around the edges of the screen (like a timer border)
- No screenshot UI shown — screenshotting is blocked silently (Android) / triggers sender notification (iOS)
- Tap anywhere to close early

### 7. Chat Settings / Theme Picker Screen
- Accessed via the info icon in chat header
- Section: **Theme** — horizontal scroll of theme chips (color swatches), one selected state with a checkmark
- Section: **Wallpaper** — grid of preset wallpapers + "Upload your own" tile
- Section: **Nicknames** — two editable text fields (Your nickname / Partner nickname)
- Section: **Notifications** — toggle for mute
- Danger zone at bottom: **Unlink Partner** (red, requires confirmation modal)

### 8. Profile Screen
- Top: Large avatar with edit overlay icon, display name, short bio (editable inline)
- Stats row: Days together, Snaps sent, Games played
- Settings list:
  - Account (email, password change)
  - Notifications
  - Privacy & Security
  - About Atmos
  - Log Out (muted red)
- Version number at the very bottom in tiny muted text

### 9. Shared Notes Screen
- Two-column layout at top:
  - **My Today** — user's daily note (editable, updates in real-time for partner)
  - **Their Today** — partner's daily note (read-only)
- Each note card has: timestamp of last update, soft background color (user = rose tint / partner = peach tint)
- Below: **Shared Notepad** — a full-width collaborative note both can edit
- Character limit indicator (500 chars per daily note)
- Real-time update dot: small animated green pulse when partner is typing

### 10. Music Screen
- Header: *"Listening Together"*
- Currently playing card (large, center):
  - Album art / YouTube thumbnail (rounded square)
  - Track name + artist
  - Shared playback progress bar (both partners control it)
  - Play/Pause, Previous, Next — both partners can tap
  - Sync status: *"Both listening ✓"* or *"Partner not listening"*
- Queue section below: list of upcoming tracks with drag-to-reorder
- Add track button: opens YouTube search modal
- Floating "Add to Queue" FAB

### 11. Games Hub Screen
- Grid of game cards (2 columns):
  - Chess (icon + "Play" / "Rematch")
  - Tic-Tac-Toe
  - Would You Rather
  - Truth or Dare
  - Word Puzzle (daily)
- Each card shows last played date and win/loss record
- Active game card has a pulsing border glow to indicate it's your turn

### 12. Chess Game Screen
- Full-screen chessboard:
  - Board uses warm dark/light square colors (not default green) — e.g., `#2D1B33` and `#C6A882`
  - Pieces styled with a clean modern flat design
- Top: Opponent avatar + name + captured pieces
- Bottom: Your avatar + name + captured pieces
- Move history panel (collapsible side drawer)
- Resign / Draw offer buttons in header menu
- Turn indicator: subtle pulsing ring around active player's avatar

---

## Global Components

### Bottom Navigation Bar
- 5 tabs: Home, Chat, Games, Music, Profile
- Active tab: rose accent icon + label, small dot indicator below
- Inactive: muted lavender icons, no label
- Floating slight elevation above content with frosted glass background

### Notifications / Toasts
- Slide in from top, frosted glass, rounded pill shape
- Types: message received, snap opened, partner online, game move made

### Modals / Bottom Sheets
- Slide up from bottom, frosted glass overlay behind
- Handle bar at top center
- Action buttons at bottom (primary + cancel)

### Empty States
- Custom warm illustrations (not generic line art) for: no messages yet, no game started, partner not linked
- Short friendly copy below each illustration

---

## Accessibility & Responsiveness

- Minimum tap target: 44×44px
- Font sizes: body min 14px, labels min 12px
- High contrast mode supported (swap to full white text on pure black)
- Safe area insets respected for iPhone notch and Android status bar
- Keyboard-aware layout — input bar rises above keyboard on focus