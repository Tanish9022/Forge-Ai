# Atmos — UI Specification & Wireframes
**Version:** 1.0  
**Date:** April 25, 2026  
**Linked PRD:** prd.md v1.1

---

## 1. Design System

### 1.1 Color Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `--bg-base` | `#0D0D1A` | App background |
| `--bg-surface` | `#1A1A2E` | Cards, sheets |
| `--bg-elevated` | `#22223B` | Input fields, secondary cards |
| `--accent-primary` | `#E8758A` | CTAs, sent bubbles, active states |
| `--accent-secondary` | `#F4A261` | Highlights, partner-side accents |
| `--text-primary` | `#F0EAE2` | Body text, headings |
| `--text-secondary` | `#8E8BA0` | Timestamps, labels, placeholders |
| `--text-danger` | `#EB5757` | Errors, unlink, delete |
| `--online-dot` | `#6FCF97` | Online indicator |
| `--glass-bg` | `rgba(26,26,46,0.6)` | Frosted glass surfaces |
| `--glass-border` | `rgba(255,255,255,0.08)` | Glass card borders |

### 1.2 Typography

| Role | Font | Weight | Size |
|------|------|--------|------|
| Display / Hero | Playfair Display | 700 | 28–36px |
| Section Heading | Playfair Display | 600 | 20–24px |
| Body | DM Sans | 400 | 15px |
| Body Bold | DM Sans | 600 | 15px |
| Label / Caption | DM Sans | 400 | 12px |
| Timestamp / Code | DM Mono | 400 | 11px |

### 1.3 Spacing Scale

| Token | Value |
|-------|-------|
| `--space-xs` | 4px |
| `--space-sm` | 8px |
| `--space-md` | 16px |
| `--space-lg` | 24px |
| `--space-xl` | 32px |
| `--space-2xl` | 48px |

### 1.4 Border Radius

| Element | Radius |
|---------|--------|
| Cards / Sheets | 20px |
| Buttons | 14px |
| Input fields | 12px |
| Sent message bubble | 18px 18px 4px 18px |
| Received message bubble | 18px 18px 18px 4px |
| Avatars | 50% (circle) |
| Chips / Tags | 999px (pill) |
| Bottom sheet handle | 4px |

### 1.5 Elevation / Shadow

| Level | Usage | Value |
|-------|-------|-------|
| 0 | Base background | none |
| 1 | Cards | `0 2px 12px rgba(0,0,0,0.3)` |
| 2 | Bottom nav, modals | `0 -4px 24px rgba(0,0,0,0.4)` |
| 3 | Toasts, FABs | `0 8px 32px rgba(232,117,138,0.25)` |

---

## 2. Navigation Architecture

```
App
├── Auth Flow (unauthenticated)
│   ├── Splash Screen
│   ├── Sign Up
│   │   └── Email Verification Waiting
│   ├── Log In
│   └── Partner Link (post sign-up only)
│
└── Main App (authenticated + linked)
    ├── Tab 1: Home
    ├── Tab 2: Chat
    │   ├── Chat Screen
    │   ├── Snap Camera
    │   ├── Snap View
    │   └── Chat Settings / Theme Picker
    ├── Tab 3: Games
    │   ├── Games Hub
    │   ├── Chess
    │   ├── Tic-Tac-Toe
    │   ├── Would You Rather
    │   ├── Truth or Dare
    │   └── Word Puzzle
    ├── Tab 4: Music
    │   └── Music Player + Queue
    └── Tab 5: Profile
        └── Edit Profile
            └── Notes Screen (accessible from Home quick-access)
```

---

## 3. Screen Wireframes

---

### SCREEN 01 — Splash / Onboarding

```
┌─────────────────────────────┐
│                             │
│   [animated gradient mesh]  │
│                             │
│                             │
│         ╔═══════╗           │
│         ║  LOGO ║           │
│         ╚═══════╝           │
│        Atmos              │
│  "Your private world,       │
│   just the two of you."     │
│                             │
│                             │
│  ┌─────────────────────┐    │
│  │      Sign Up        │    │  ← filled rose button
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │       Log In        │    │  ← ghost/outlined button
│  └─────────────────────┘    │
│                             │
│   [floating bokeh particles]│
└─────────────────────────────┘
```

**Notes:**
- Background: animated gradient mesh (rose → peach → midnight navy)
- Logo: interlocking rings or lock-heart hybrid SVG
- Buttons full-width with `--space-md` horizontal padding
- Bottom safe area padding respected

---

### SCREEN 02 — Sign Up

```
┌─────────────────────────────┐
│  ←  Back                    │
│                             │
│   Create your account       │  ← Playfair Display 28px
│   Start your private space  │  ← DM Sans muted 14px
│                             │
│  ┌─────────────────────┐    │
│  │ Email               │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ Password       👁   │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ Confirm Password 👁 │    │
│  └─────────────────────┘    │
│                             │
│  [error text in --danger]   │
│                             │
│  ┌─────────────────────┐    │
│  │   Create Account    │    │  ← primary button
│  └─────────────────────┘    │
│                             │
│  Already have an account?   │
│  Log In                     │  ← inline text link
└─────────────────────────────┘
```

**Email Verification State:**
```
┌─────────────────────────────┐
│                             │
│      [envelope illustration]│
│                             │
│  Check your inbox           │  ← Playfair 24px
│  We sent a link to          │
│  you@example.com            │  ← bold email
│                             │
│  ┌─────────────────────┐    │
│  │   Open Mail App     │    │
│  └─────────────────────┘    │
│                             │
│  Didn't receive it?         │
│  Resend (available in 60s)  │  ← countdown timer
└─────────────────────────────┘
```

---

### SCREEN 03 — Log In

```
┌─────────────────────────────┐
│  ←  Back                    │
│                             │
│   Welcome back              │  ← Playfair Display 28px
│                             │
│  ┌─────────────────────┐    │
│  │ Email               │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ Password       👁   │    │
│  └─────────────────────┘    │
│                             │
│  Forgot password?           │  ← right-aligned text link
│                             │
│  ┌─────────────────────┐    │
│  │       Log In        │    │
│  └─────────────────────┘    │
│                             │
│  Don't have an account?     │
│  Sign Up                    │
└─────────────────────────────┘
```

---

### SCREEN 04 — Partner Link

```
┌─────────────────────────────┐
│  ●●○  Step 2 of 2           │  ← progress dots
│                             │
│   Find your person          │  ← Playfair 28px
│   Share your code or enter  │
│   theirs to connect         │
│                             │
│  ┌──────────┐  ┌──────────┐ │
│  │  YOUR    │  │  THEIR   │ │
│  │  CODE    │  │  CODE    │ │
│  │          │  │          │ │
│  │ A3K9PW   │  │ [______] │ │  ← 6-char code / input
│  │          │  │          │ │
│  │ [Copy]   │  │[Connect] │ │
│  │ [Share]  │  │          │ │
│  └──────────┘  └──────────┘ │
│                             │
│     [animated link icon]    │
│                             │
│   Code expires in 10:00     │  ← countdown in DM Mono
└─────────────────────────────┘
```

---

### SCREEN 05 — Home

```
┌─────────────────────────────┐
│  Atmos        🔔           │
│─────────────────────────────│
│                             │
│  ┌─────────────────────┐    │
│  │ 🟢●  [Avatar]       │    │
│  │  Sarah              │    │  ← partner name
│  │  "babe" ←nickname   │    │
│  │  ❤️ 247 days together│    │
│  │─────────────────────│    │
│  │ 🔒 Hey, what time...│    │  ← last message preview
│  │               2m    │    │  ← timestamp
│  └─────────────────────┘    │
│                             │
│  Quick Access               │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐│
│  │📝  │ │♟   │ │🎵  │ │📸  ││  ← Notes, Games, Music, Snaps
│  │Note│ │Game│ │Music│ │Snap││
│  └────┘ └────┘ └────┘ └────┘│
│                             │
│─────────────────────────────│
│  🏠   💬   🎮   🎵   👤     │  ← bottom nav
└─────────────────────────────┘
```

---

### SCREEN 06 — Chat Screen

```
┌─────────────────────────────┐
│  ← [Avatar] Sarah    ⓘ     │  ← header bar
│─────────────────────────────│
│  [chat wallpaper / blur bg] │
│                             │
│  ┌────────────────────┐     │
│  │ Hey! How was your  │     │  ← received bubble (glass)
│  │ day? 🌙            │     │
│  │              🔒 9:41│     │
│  └────────────────────┘     │
│                             │
│         ┌────────────────┐  │
│         │ Good! Just got │  │  ← sent bubble (rose gradient)
│         │ home finally   │  │
│         │ 🔒        9:43 │  │
│         └────────────────┘  │
│                             │
│  [SNAP indicator card]      │
│  ┌─────────────────────┐    │
│  │ 📸 Snap • Tap to    │    │  ← unopened snap
│  │    view (expires 23h│    │
│  └─────────────────────┘    │
│                             │
│─────────────────────────────│
│ 📷  📎  🖼  [Say something..]  ➤ │
└─────────────────────────────┘
```

**Bubble detail:**
- Sent: `background: linear-gradient(135deg, #E8758A, #C45C72)`, white text
- Received: `background: rgba(26,26,46,0.7)`, blur, `--text-primary`
- 🔒 icon: 9px, `--text-secondary`, always visible on bubble

---

### SCREEN 07 — Snap Camera

```
┌─────────────────────────────┐
│  ✕                          │  ← close
│                             │
│                             │
│   [full-screen camera       │
│    viewfinder]              │
│                             │
│                             │
│                             │
│  ┌──────────────────────┐   │
│  │  1s  3s  5s  10s     │   │  ← timer selector chips
│  └──────────────────────┘   │
│                             │
│       ╔═══════════╗         │
│       ║  [SHUTTER]║         │  ← large circular button
│       ╚═══════════╝         │
│                             │
│  🔄 (flip camera)           │
└─────────────────────────────┘
```

---

### SCREEN 08 — Snap View

```
┌─────────────────────────────┐
│                             │
│  [countdown ring border     │
│   animates around screen    │
│   edges — 5s timer]         │
│                             │
│                             │
│   [full-screen snap image   │
│    or video content]        │
│                             │
│                             │
│  Tap anywhere to close      │  ← small muted hint text
│                             │
└─────────────────────────────┘
```

**Notes:**
- No UI chrome except the timer ring and hint text
- Screenshot silently blocked (Android) / triggers notification (iOS)
- After timer: blurs out → auto-closes

---

### SCREEN 09 — Chat Settings / Theme Picker

```
┌─────────────────────────────┐
│  ←  Chat Settings           │
│─────────────────────────────│
│                             │
│  THEME                      │
│  ──────────────────         │
│  [●Rose] [○Ocean] [○Forest] │  ← horizontal scroll chips
│  [○Midnight] [○Custom...]   │
│                             │
│  WALLPAPER                  │
│  ──────────────────         │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐       │
│  │🌸│ │🌙│ │🌊│ │+  │       │  ← preset grid + upload
│  └──┘ └──┘ └──┘ └──┘       │
│                             │
│  NICKNAMES                  │
│  ──────────────────         │
│  You:     [babe_______]     │
│  Partner: [love_______]     │
│                             │
│  NOTIFICATIONS              │
│  ──────────────────         │
│  Mute conversation   ○──●   │  ← toggle
│                             │
│  ─────────────────────────  │
│  [Unlink Partner]           │  ← danger red, bottom
└─────────────────────────────┘
```

---

### SCREEN 10 — Profile

```
┌─────────────────────────────┐
│  Profile                    │
│─────────────────────────────│
│                             │
│       ╔════════╗            │
│       ║ Avatar ║  ✏️         │  ← edit overlay
│       ╚════════╝            │
│       Your Name             │
│       Short bio here        │  ← tappable to edit inline
│                             │
│  ┌─────────┬────────┬──────┐│
│  │247 days │ 84 snaps│ 12 W ││  ← stats row
│  │together │  sent   │games ││
│  └─────────┴────────┴──────┘│
│                             │
│  Account                  › │
│  Notifications            › │
│  Privacy & Security       › │
│  About Atmos            › │
│                             │
│  Log Out                    │  ← muted red
│                             │
│          v1.0.0             │  ← tiny muted version
└─────────────────────────────┘
```

---

### SCREEN 11 — Notes Screen

```
┌─────────────────────────────┐
│  ← Notes                   │
│─────────────────────────────│
│                             │
│  TODAY'S UPDATES            │
│  ──────────────────         │
│  ┌──────────────┐ ┌────────┐│
│  │ YOUR DAY     │ │HER DAY ││
│  │ (rose tint)  │ │(peach) ││
│  │              │ │        ││
│  │ Tap to write │ │Just    ││
│  │ your update  │ │got home││
│  │              │ │ coffee ││
│  │     0/500    │ │updated ││
│  │              │ │ 6:30pm ││
│  └──────────────┘ └────────┘│
│  [● partner is typing...]   │  ← live indicator
│                             │
│  SHARED NOTEPAD             │
│  ──────────────────         │
│  ┌─────────────────────┐    │
│  │ Movie list:         │    │
│  │ - Interstellar ✓   │    │
│  │ - La La Land       │    │
│  │ - [type here...]   │    │  ← collaborative note
│  └─────────────────────┘    │
└─────────────────────────────┘
```

---

### SCREEN 12 — Music Screen

```
┌─────────────────────────────┐
│  🎵 Listening Together      │
│─────────────────────────────│
│                             │
│  ┌─────────────────────┐    │
│  │  [Album Thumbnail]  │    │
│  │                     │    │
│  │  Lover — Taylor S.  │    │
│  │  ✓ Both listening   │    │  ← sync status
│  │                     │    │
│  │  ━━━━━━●────────    │    │  ← shared progress bar
│  │  1:42        3:41   │    │
│  │                     │    │
│  │    ⏮   ⏸   ⏭       │    │  ← controls (both can use)
│  └─────────────────────┘    │
│                             │
│  UP NEXT                    │
│  ──────────────────         │
│  ┌─────────────────────┐    │
│  │ ≡  Cornelia St.     │    │  ← draggable queue items
│  │ ≡  Enchanted        │    │
│  └─────────────────────┘    │
│                             │
│           [+ Add Song]      │  ← FAB bottom right
└─────────────────────────────┘
```

---

### SCREEN 13 — Games Hub

```
┌─────────────────────────────┐
│  🎮 Games                   │
│─────────────────────────────│
│                             │
│  ┌──────────┐  ┌──────────┐ │
│  │ ♟ Chess  │  │ ✗ Tic-   │ │
│  │          │  │   Tac-Toe│ │
│  │ Last: 2d │  │ You: 3W  │ │
│  │ [PLAY]   │  │ [PLAY]   │ │  ← YOUR TURN glow on active
│  └──────────┘  └──────────┘ │
│                             │
│  ┌──────────┐  ┌──────────┐ │
│  │ 💭 Would │  │ 🎯 Truth │ │
│  │  You     │  │  or Dare │ │
│  │  Rather  │  │          │ │
│  │ [PLAY]   │  │ [PLAY]   │ │
│  └──────────┘  └──────────┘ │
│                             │
│  ┌──────────────────────┐   │
│  │ 🔤 Daily Word Puzzle │   │
│  │  Today's score: --   │   │
│  │        [PLAY]        │   │
│  └──────────────────────┘   │
└─────────────────────────────┘
```

---

### SCREEN 14 — Chess Game

```
┌─────────────────────────────┐
│  ← Chess    ··· [History]   │
│─────────────────────────────│
│  [Partner Avatar]  Sarah    │
│  Captured: ♙♙♗              │
│─────────────────────────────│
│                             │
│  ┌─────────────────────┐    │
│  │ ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜  │    │
│  │ ♟ ♟ ♟ ♟ ♟ ♟ ♟ ♟  │    │
│  │ .  .  .  .  .  .  │    │
│  │ .  .  .  .  .  .  │    │
│  │ .  .  .  ♙ .  .   │    │
│  │ .  .  .  .  .  .  │    │
│  │ ♙ ♙ ♙ .  ♙ ♙ ♙ ♙  │    │
│  │ ♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖  │    │
│  └─────────────────────┘    │
│                             │
│─────────────────────────────│
│  [Your Avatar]  You         │
│  Captured: ♟               │
│  ● Your turn                │  ← pulsing dot
└─────────────────────────────┘
```

---

## 4. Bottom Navigation Bar

```
┌─────────────────────────────┐
│  🏠    💬    🎮    🎵    👤  │
│  Home  Chat  Games Music Me │
│   ●                         │  ← active dot below icon
└─────────────────────────────┘
```

| Tab | Icon | Label | Active State |
|-----|------|-------|-------------|
| Home | House icon | Home | Rose icon + dot |
| Chat | Chat bubble | Chat | Rose icon + dot + unread badge |
| Games | Gamepad | Games | Rose icon + dot |
| Music | Music note | Music | Rose icon + dot |
| Profile | Person | Me | Rose icon + dot |

- Height: 64px + safe area bottom inset
- Background: `--glass-bg` + `--glass-border` border top
- No labels on inactive tabs

---

## 5. Toast / Notification Components

```
┌───────────────────────────────────┐
│ [avatar] Sarah sent you a snap 📸 │  ← message toast
│                          now  ✕   │
└───────────────────────────────────┘

┌───────────────────────────────────┐
│ ⚠️  Sarah took a screenshot!       │  ← snap alert
└───────────────────────────────────┘

┌───────────────────────────────────┐
│ ♟  Sarah made a move in Chess     │  ← game toast
└───────────────────────────────────┘
```

- Slide in from top, `border-radius: 999px` pill
- Auto-dismiss after 4 seconds
- Background: `--glass-bg` + 1px `--glass-border`
- Tap to open relevant screen

---

## 6. Modal / Bottom Sheet

```
┌─────────────────────────────┐
│                             │
│                             │
│  ─── [drag handle] ───      │
│                             │
│  Are you sure?              │  ← heading
│  Unlinking will remove your │
│  access to the shared chat. │  ← body
│                             │
│  ┌─────────────────────┐    │
│  │   Yes, Unlink       │    │  ← danger button
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │      Cancel         │    │  ← ghost button
│  └─────────────────────┘    │
└─────────────────────────────┘
```

---

## 7. Empty States

| Screen | Illustration | Copy |
|--------|-------------|------|
| Chat (no messages) | Two speech bubbles with hearts | *"Say hello! Your messages are encrypted end-to-end."* |
| Music (no queue) | Headphones illustration | *"Add a song and listen together."* |
| Games (no active game) | Game controller | *"Start a game and challenge each other."* |
| Notes (partner hasn't written) | Open notebook | *"Waiting for their update..."* |
| Not linked | Two people reaching toward each other | *"Share your invite code to connect with your partner."* |

---

## 8. Interaction States

| Component | Default | Hover/Focus | Active/Pressed | Disabled |
|-----------|---------|-------------|----------------|----------|
| Primary Button | Rose fill | Brighten 10% | Scale 0.97 | 40% opacity |
| Ghost Button | Transparent + border | Fill 10% rose | Scale 0.97 | 40% opacity |
| Input Field | `--bg-elevated` border | Rose border glow | Rose border | Greyed border |
| Message Bubble | Static | — | Slight scale on long-press (context menu) | — |
| Bottom Nav Icon | Muted | — | Scale 1.1 + rose | — |
| Game Card | Static | Rose border | Scale 0.98 | Greyed |

---

## 9. Responsive Breakpoints

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Mobile (primary) | 375–430px | Single column, bottom nav |
| Tablet (PWA landscape) | 768px+ | Two-panel: nav sidebar left, content right |
| Desktop (browser PWA) | 1024px+ | Fixed 430px centered app shell, dark flanks |

---

*This document is the single source of truth for all UI decisions. Any design changes must be reflected here before implementation.*