# FRONTEND.md — Atmos UI/UX Design Specification

> Flutter frontend design system, screen layouts, component library, navigation, animations, and
> implementation guidelines for the Atmos couples messaging app.

---

## 1. Design Philosophy

Atmos should feel **warm, intimate, and premium** — not clinical or corporate.
The UI borrows from three references:

| Reference | What we borrow |
|---|---|
| Snapchat | Camera-first snaps flow, ephemeral content feel |
| Instagram DMs | Chat themes, media in conversation, profile richness |
| Notion | Clean notepad, readable typography, calm information density |

**Core principles:**
- **Intimacy over information density** — generous whitespace, large touch targets, soft corners
- **Delight in motion** — every state transition earns a micro-animation
- **Dark-first** — the default theme is dark; couples often use phones at night
- **Private by default** — no public feeds, no discovery, no social graph visible in UI

---

## 2. Design Tokens

Define these in a single `app_theme.dart` file and reference everywhere.

### 2.1 Color Palette

```dart
// lib/core/theme/app_colors.dart

class AppColors {
  // Primary — Rose (CTA, sent bubbles, active nav)
  static const rose500    = Color(0xFFFF4F6D);
  static const rose600    = Color(0xFFC42040);
  static const rose100    = Color(0xFFFFE0E6);
  static const rose50     = Color(0xFFFFF0F3);

  // Secondary — Deep Plum (nav bar, headers, dark surfaces)
  static const plum900    = Color(0xFF1A0B30);
  static const plum800    = Color(0xFF2D1B4E);
  static const plum700    = Color(0xFF3D2566);
  static const plum500    = Color(0xFF7B5EA7);
  static const plum200    = Color(0xFFCAB8E8);

  // Accent — Gold (achievements, streaks, premium moments)
  static const gold500    = Color(0xFFF5A623);
  static const gold100    = Color(0xFFFFF3DC);

  // Semantic
  static const mint500    = Color(0xFF00C9A7);   // online, success
  static const mint100    = Color(0xFFD4F5EF);
  static const red500     = Color(0xFFE53E3E);   // error, delete
  static const red100     = Color(0xFFFED7D7);

  // Neutral — Dark mode surfaces
  static const gray950    = Color(0xFF0D0D0D);   // page bg dark
  static const gray900    = Color(0xFF181818);   // card bg dark
  static const gray800    = Color(0xFF242424);   // input bg dark
  static const gray700    = Color(0xFF363636);   // divider dark
  static const gray400    = Color(0xFF9CA3AF);   // secondary text dark
  static const gray200    = Color(0xFFE5E7EB);   // secondary text light
  static const gray100    = Color(0xFFF3F4F6);   // card bg light
  static const gray50     = Color(0xFFFAFAFA);   // page bg light

  // Always white / always black
  static const white      = Color(0xFFFFFFFF);
  static const black      = Color(0xFF000000);
}
```

### 2.2 Typography

```dart
// lib/core/theme/app_text_styles.dart
// Font: Syne (headings) + DM Sans (body) — both free on Google Fonts

import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Display — used on splash, onboarding, section titles
  static TextStyle display1 = GoogleFonts.syne(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0);
  static TextStyle display2 = GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5);

  // Headings
  static TextStyle h1 = GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700);
  static TextStyle h2 = GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700);
  static TextStyle h3 = GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w600);

  // Body
  static TextStyle bodyLg  = GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);
  static TextStyle bodyMd  = GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle bodySm  = GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  // UI labels
  static TextStyle labelLg = GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle labelMd = GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500);
  static TextStyle labelSm = GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8);

  // Mono (timestamps, codes)
  static TextStyle mono = GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w400);
}
```

### 2.3 Spacing & Radius

```dart
// lib/core/theme/app_spacing.dart

class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 48.0;
}

class AppRadius {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 18.0;
  static const double xl   = 24.0;
  static const double full = 999.0;  // pills, avatars
}
```

### 2.4 Shadows & Elevation

```dart
class AppShadows {
  // Use sparingly — only on floating elements
  static const cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const popoverShadow = [
    BoxShadow(color: Color(0x22000000), blurRadius: 40, offset: Offset(0, 8)),
  ];
}
```

---

## 3. Theme Configuration

```dart
// lib/core/theme/app_theme.dart

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.gray950,
  primaryColor: AppColors.rose500,
  colorScheme: ColorScheme.dark(
    primary: AppColors.rose500,
    secondary: AppColors.plum500,
    surface: AppColors.gray900,
    background: AppColors.gray950,
    error: AppColors.red500,
  ),
  // Bottom nav, cards, inputs inherit from colorScheme
);

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.gray50,
  primaryColor: AppColors.rose500,
  colorScheme: ColorScheme.light(
    primary: AppColors.rose500,
    secondary: AppColors.plum700,
    surface: AppColors.white,
    background: AppColors.gray50,
    error: AppColors.red500,
  ),
);
```

---

## 4. Navigation Architecture

### 4.1 Router Structure (GoRouter)

```
/                         → SplashScreen
/onboarding               → OnboardingFlow
  /onboarding/signup      → SignUpScreen
  /onboarding/login       → LoginScreen
  /onboarding/profile     → ProfileSetupScreen
  /onboarding/link        → CoupleLinkScreen

/home                     → HomeShell (BottomNavBar)
  /home/chat              → ChatScreen (default tab)
  /home/snaps             → SnapsScreen
  /home/together          → TogetherScreen (music + games hub)
  /home/notes             → NotesScreen
  /home/profile           → ProfileScreen

/chat/camera              → SnapCameraScreen (full screen, modal)
/chat/snap-view/:id       → SnapViewScreen (full screen, timed)
/music/player             → MusicPlayerScreen
/games/:gameId            → GameScreen (Chess / TicTacToe / etc.)
/notes/compose            → NoteComposeScreen
/profile/edit             → ProfileEditScreen
/settings                 → SettingsScreen
  /settings/theme         → ThemePickerScreen
  /settings/privacy       → PrivacyScreen
  /settings/security      → SecurityScreen
```

### 4.2 Bottom Navigation Bar

```dart
// 5 tabs — icon + label, rose active indicator

BottomNavigationBar(
  items: [
    BottomNavItem(icon: Icons.chat_bubble_rounded,   label: 'Chat'),
    BottomNavItem(icon: Icons.circle_rounded,        label: 'Snaps'),   // dot = Snap style
    BottomNavItem(icon: Icons.favorite_rounded,      label: 'Together'),
    BottomNavItem(icon: Icons.sticky_note_2_rounded, label: 'Notes'),
    BottomNavItem(icon: Icons.person_rounded,        label: 'You'),
  ],
  selectedItemColor: AppColors.rose500,
  unselectedItemColor: AppColors.gray400,
  backgroundColor: dark ? AppColors.gray900 : AppColors.white,
  type: BottomNavigationBarType.fixed,
  elevation: 0,
  // Custom: draw a rose 4dp underline pill on active item (not default indicator)
)
```

---

## 5. Screen Specifications

---

### Screen 01 — Splash Screen

**Purpose:** Brand moment + auth state check

**Layout:**
```
┌─────────────────────────────┐
│                             │
│                             │
│         ●  Atmos            │  ← Logo: rose dot + Syne 28px bold
│                             │
│    ──────────────────────   │  ← animated gradient shimmer line
│                             │
│                             │
└─────────────────────────────┘
```

**Behaviour:**
- Background: animated slow gradient morph between plum900 → plum700
- Logo fades in over 600ms with slight upward translate (0 → -8px)
- After 1.8s: check API auth session (JWT in secure storage)
  - Authenticated + linked → push `/home/chat`
  - Authenticated + not linked → push `/onboarding/link`
  - Not authenticated → push `/onboarding`

---

### Screen 02 — Onboarding Flow

**Step 1 — Welcome**
```
┌─────────────────────────────┐
│  ← skip                     │
│                             │
│   [illustration: two people │
│    with hearts, SVG/Lottie] │
│                             │
│  Your private space         │  ← Syne h1
│  Just the two of you.       │  ← DM Sans bodyMd, gray400
│                             │
│  ┌─────────────────────┐   │
│  │   Get Started  →    │   │  ← rose500 filled button
│  └─────────────────────┘   │
│                             │
│  Already have an account?   │  ← text button, gray400
│  Sign In                    │
└─────────────────────────────┘
```

**Step 2 — Sign Up**
```
┌─────────────────────────────┐
│  ←  Create Account          │
│                             │
│  [  Email address         ] │  ← outlined input, AppRadius.md
│  [  Password              ] │
│  [  Confirm password      ] │
│                             │
│  ─────── or ───────         │
│                             │
│  [G]  Continue with Google  │  ← outlined button, Google brand
│                             │
│  ┌─────────────────────┐   │
│  │   Create Account    │   │
│  └─────────────────────┘   │
│                             │
│  By continuing you agree    │
│  to our Terms & Privacy     │
└─────────────────────────────┘
```

**Step 3 — Profile Setup**
```
┌─────────────────────────────┐
│  Step 2 of 3                │  ← progress indicator, rose500
│                             │
│       [  avatar tap  ]      │  ← 80px circle, tap to upload
│     Upload your photo       │
│                             │
│  [  Your name             ] │
│  [  Bio (optional)        ] │
│  [  Status emoji + text   ] │
│                             │
│  Anniversary date (optional)│
│  [  📅  Jan 14, 2023      ] │
│                             │
│  ┌─────────────────────┐   │
│  │   Continue  →       │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

**Step 4 — Couple Link**
```
┌─────────────────────────────┐
│  Step 3 of 3                │
│                             │
│  Link with your partner     │  ← Syne h1
│                             │
│  ┌───────────────────────┐ │
│  │   Your code           │ │
│  │                       │ │
│  │     4  8  F  2  9  K  │ │  ← 6-char code, mono 32px, spaced
│  │                       │ │
│  │  [  Copy code  ]      │ │
│  └───────────────────────┘ │
│                             │
│  ─────── or ───────         │
│                             │
│  Have a code?               │
│  [  Enter partner's code  ] │
│                             │
│  ┌─────────────────────┐   │
│  │   Link Partner      │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

---

### Screen 03 — Chat Screen

**App Bar:**
```
┌─────────────────────────────────────────┐
│  [S]  Sophia ♡           📞  📹  ⋮     │
│       ● Online · typing...              │
└─────────────────────────────────────────┘
```
- Left: partner avatar (40px circle) + name (Syne h2) + status row
- Right: call, video, overflow menu icons
- Sticky theme-color bar below: 6 theme dots + "Theme" label

**Chat Theme Bar:**
```
┌─────────────────────────────────────────┐
│  Theme  ●  ●  ●  ●  ●  ●              │
│         ^rose ^plum ^ocean ^mint...    │
└─────────────────────────────────────────┘
```
- Height: 36dp, subtle border-bottom divider
- Active dot: 20dp with 2dp white ring + outer shadow
- Inactive dot: 16dp

**Message List:**
```
                              ┌────────────────────┐
                              │ Really well! 🥰    │  ← mine: rose bubble
                              │            8:16 ✓✓ │
                              └────────────────────┘

  [S] ┌──────────────────────┐
      │ Good morning babe ☀️ │  ← theirs: surface card bubble
      │ 8:14                 │
      └──────────────────────┘

  [S] ┌──────────────────────┐
      │ 📸 New Snap!         │  ← snap notification bubble (plum bg)
      │ Tap to view · 10s    │
      └──────────────────────┘
```

**Message Bubble Specs:**
- Own messages: aligned right, `rose500` background, white text, `BorderRadius.only(topLeft, topRight, bottomLeft all 18, bottomRight 4)`
- Partner messages: aligned left, `gray900` (dark) / `white` (light) background, `BorderRadius.only(topLeft 4, others 18)`
- Max width: 75% of screen width
- Padding: 10px vertical, 16px horizontal
- Timestamp: 11px, gray400, below bubble right-aligned

**Input Bar:**
```
┌─────────────────────────────────────────┐
│  [📸]  [  Message Sophia...       ]  [→]│
└─────────────────────────────────────────┘
```
- Snap button (left): 44dp tap target, opens SnapCameraScreen
- Text field: auto-expanding, max 6 lines, soft border
- Send button: 44dp rose circle, paper-plane icon
- Additional icons (long-press or swipe input): 🎤 voice, 📎 media, GIF

**Reactions:**
- Long-press bubble → emoji picker floats above in a `showModalBottomSheet`
- Reactions appear as small overlapping circles below the bubble

---

### Screen 04 — Snap Camera Screen (Full Screen)

```
┌─────────────────────────────┐
│  ✕                    ⚙️   │  ← top bar, 40% opacity bg
│                             │
│                             │
│     [CAMERA VIEWFINDER]     │
│                             │
│                             │
│  ────────────────────────   │
│     🖊   T   ⭐   Aa         │  ← tool strip (draw, text, sticker, font)
│  ────────────────────────   │
│                             │
│         ◯                   │  ← 72dp shutter button
│    [gallery]  [flip 🔄]     │
│                             │
│  ──── Timer ────────────    │
│  1s  3s  5s  10s  ∞        │
└─────────────────────────────┘
```

**Shutter button behaviour:**
- Tap → take photo (flash animation overlay)
- Hold → record video (progress ring animates around button, max 15s)
- Release → stop recording

**After capture — Edit mode:**
- Pinch to resize text overlay
- Drag to reposition stickers/text
- Undo button top-left
- Send button bottom-right (rose, 56dp, "Send to Sophia →")

---

### Screen 05 — Snap View Screen (Full Screen, Timed)

```
┌─────────────────────────────┐
│  Sophia  ──────────────     │  ← timer progress bar (depletes L→R)
│  ⏱ 5s                      │
│                             │
│                             │
│      [SNAP IMAGE/VIDEO]     │
│                             │
│                             │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│  Hold to pause              │  ← hint, fades after 1s
└─────────────────────────────┘
```
- Full-bleed photo/video, no chrome except timer bar
- Hold to pause timer
- When timer expires: animate opacity 1→0, navigate back
- Screenshot → FCM notification sent to partner

---

### Screen 06 — Snaps Tab

**Layout — Two-column grid of snap cards:**
```
┌──────────────┬──────────────┐
│              │              │
│  🌅           │  ☕           │
│  [gradient]  │  [gradient]  │
│  From Sophia │  From Sophia │
│  Just now    │  2h ago      │
│  [UNSEEN]    │  [UNSEEN]    │
├──────────────┼──────────────┤
│              │              │
│  [viewed]    │  [viewed]    │
│  Yesterday   │  2 days ago  │
│  opacity 50% │  opacity 50% │
└──────────────┴──────────────┘
```

- Card aspect ratio: 9:16
- Unseen: full opacity, rose border 2dp
- Viewed: 50% opacity, no border
- Snap timer badge: top-right, `⏱ 10s` in frosted pill
- FAB: bottom-right, rose circle with camera icon → SnapCameraScreen

---

### Screen 07 — Together Screen (Hub)

**Listen Together section (top half):**
```
┌─────────────────────────────┐
│  Listen Together            │  ← Syne h2
│  ● Both listening           │  ← mint500, animated pulse dot
│                             │
│  ┌─────────────────────┐   │
│  │  🎵                  │   │  ← album art, 100px, rounded-lg
│  │  Golden Hour        │   │
│  │  JVKE               │   │
│  │  ─────●─────────    │   │  ← progress bar
│  │  1:23          3:38 │   │
│  │  ⏮   ⏸   ⏭        │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

**Games section (bottom half):**
```
┌─────────────────────────────┐
│  Play Together              │
│                             │
│  ┌────────┐  ┌────────┐   │
│  │ ♟️ Chess│  │ ✕○ TTT │   │  ← 2-col grid, 160dp square cards
│  │ Play ↗ │  │ Play ↗ │   │
│  └────────┘  └────────┘   │
│  ┌────────┐  ┌────────┐   │
│  │ 💜 T&D │  │ 🧩 Word│   │
│  │ Play ↗ │  │ Play ↗ │   │
│  └────────┘  └────────┘   │
└─────────────────────────────┘
```

---

### Screen 08 — Chess Game Screen

```
┌─────────────────────────────┐
│  ←   Chess      Score 2-1   │
│      [Sophia's timer 4:32]  │  ← red countdown when < 1 min
│                             │
│  ┌─────────────────────┐   │
│  │  [8×8 Chess Board]  │   │  ← flutter_chess_board widget
│  │  Draggable pieces   │   │
│  └─────────────────────┘   │
│                             │
│      [Your timer 3:58]      │
│                             │
│  [Move history]  [⚑ Resign] │
└─────────────────────────────┘
```

- Board fills ~80% of screen width, centred
- Alternating squares: plum200 (light) / plum700 (dark)
- Piece drag: scale 1.2× + shadow while dragging
- Valid move destinations: mint dot overlay on squares
- Last move: highlighted with gold50 background

---

### Screen 09 — Notes Screen

**Header:**
```
┌─────────────────────────────────────┐
│  Our Notes          [+ Add Note]    │
│  ┌──────────┬──────────┬──────────┐ │
│  │  All     │  Sophia  │  Alex    │ │  ← filter tabs
│  └──────────┴──────────┴──────────┘ │
└─────────────────────────────────────┘
```

**Note Card:**
```
┌─────────────────────────────────────┐
│  [S]  Sophia              Today 7:30│
│  ─────────────────────────────────  │
│  Good morning! Today I have yoga at │
│  8am, then a meeting at 11...       │
│                                     │
│  [Routine]              ♥  Reply   │
└─────────────────────────────────────┘
```

- Card: white (light) / gray900 (dark), 16px radius, subtle shadow
- Avatar: 28dp circle, initials
- Type badge: rose100 bg, rose600 text for Routine; gold100/gold600 for Reminder; plum100/plum600 for Love Note; mint100/mint600 for Plan
- Bottom row: type badge left, reaction + reply right

**Compose Screen:**
```
┌─────────────────────────────┐
│  ✕  New Note       [Post]  │
│                             │
│  Type: [Routine  ▾]        │  ← dropdown chip selector
│                             │
│  ┌─────────────────────┐   │
│  │                     │   │
│  │  (write here...)    │   │  ← auto-focus, 8-line min height
│  │                     │   │
│  └─────────────────────┘   │
│                             │
│  📅 Add reminder date       │
│  😊 Add emoji               │
│  B  I  •  (formatting)     │
└─────────────────────────────┘
```

---

### Screen 10 — Profile Screen

```
┌─────────────────────────────┐
│  ─────────────────────────  │  ← gradient banner, plum→rose
│                             │
│  [A]  Alex                 │  ← 80dp avatar, white border
│       In love with Sophia  │
│       "Music lover 🎵"      │
│                             │
│  ┌────────┬────────┬──────┐ │
│  │  347   │  2.4k  │  841 │ │
│  │ Snaps  │  Msgs  │ Days │ │
│  └────────┴────────┴──────┘ │
│                             │
│  SETTINGS                   │
│  🎨  Chat Theme         ›   │
│  🔔  Notifications      ›   │
│  🔒  Privacy & Security ›   │
│  💑  Couple Settings    ›   │
│  🌙  Appearance         ›   │
│  📤  Export Notes       ›   │
│  🚪  Sign Out               │
└─────────────────────────────┘
```

---

## 6. Component Library

### 6.1 Buttons

```dart
// Primary — rose filled
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.rose500,
    foregroundColor: AppColors.white,
    minimumSize: Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    elevation: 0,
  ),
  child: Text('Continue', style: AppTextStyles.labelLg),
)

// Secondary — outlined
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.rose500,
    side: BorderSide(color: AppColors.rose500, width: 1.5),
    minimumSize: Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  ),
)

// Ghost — text only
TextButton(
  style: TextButton.styleFrom(foregroundColor: AppColors.gray400),
)

// Danger
ElevatedButton.styleFrom(backgroundColor: AppColors.red500)
```

### 6.2 Text Inputs

```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Email address',
    hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.gray400),
    filled: true,
    fillColor: dark ? AppColors.gray800 : AppColors.gray100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: AppColors.rose500, width: 1.5),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
)
```

### 6.3 Avatar Widget

```dart
// Sizes: sm (28), md (40), lg (60), xl (80)
Widget avatar({required String initials, String? photoUrl, double size = 40}) {
  return CircleAvatar(
    radius: size / 2,
    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
    backgroundColor: AppColors.rose500,
    child: photoUrl == null
        ? Text(initials, style: AppTextStyles.labelLg.copyWith(color: Colors.white))
        : null,
  );
}
```

### 6.4 Online Indicator

```dart
// Animated green pulse dot — overlays bottom-right of avatar
Stack(children: [
  avatar(...),
  Positioned(bottom: 1, right: 1, child: AnimatedPulseDot(color: AppColors.mint500, size: 10)),
])
```

### 6.5 Message Bubble

```dart
class MessageBubble extends StatelessWidget {
  final bool isOwn;
  final String text;
  final String time;
  final Color themeColor; // from selected chat theme

  BorderRadius get _radius => isOwn
      ? BorderRadius.only(
          topLeft: Radius.circular(18), topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4))
      : BorderRadius.only(
          topLeft: Radius.circular(4), topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18));

  Color get _bg => isOwn ? themeColor : (isDark ? AppColors.gray900 : AppColors.white);
  Color get _fg => isOwn ? Colors.white : (isDark ? Colors.white : AppColors.plum800);
}
```

### 6.6 Tag / Badge

```dart
// Type badge on notes
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
  decoration: BoxDecoration(
    color: badgeBg,       // e.g. AppColors.rose100
    borderRadius: BorderRadius.circular(AppRadius.full),
  ),
  child: Text(label, style: AppTextStyles.labelSm.copyWith(color: badgeFg)),
)
```

### 6.7 Bottom Sheet

```dart
// Standard bottom sheet style
showModalBottomSheet(
  context: context,
  backgroundColor: dark ? AppColors.gray900 : AppColors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => DragHandle(), // 36×4 pill, gray700
);
```

### 6.8 Snap Card (Grid Item)

```dart
AspectRatio(
  aspectRatio: 9 / 16,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.xl),
    child: Stack(children: [
      // Gradient background or actual image
      Container(decoration: BoxDecoration(gradient: snapGradient)),
      // Overlay: footer info + timer badge
      Positioned(bottom: 0, child: snapFooter),
      if (!viewed) Positioned(top: 12, right: 12, child: timerBadge),
    ]),
  ),
)
```

---

## 7. Animations

Use `flutter_animate` package for all animations. Avoid `AnimationController` boilerplate for simple cases.

### 7.1 Page Transitions

```dart
// Slide up from bottom — for modals and detail screens
CustomTransitionPage(
  transitionsBuilder: (_, animation, __, child) =>
      SlideTransition(
        position: Tween(begin: Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child),
)

// Fade + scale — for snap view
FadeTransition + ScaleTransition(scale: Tween(0.92, 1.0))
```

### 7.2 Message Send Animation

```dart
// New sent message slides in from right + fades in
MessageBubble()
  .animate()
  .slideX(begin: 0.3, duration: 250.ms, curve: Curves.easeOutCubic)
  .fadeIn(duration: 200.ms)
```

### 7.3 Online Pulse Dot

```dart
// Repeating scale pulse
Widget build(_) => AnimatedBuilder(
  animation: _controller, // repeat 0→1→0
  builder: (_, __) => Transform.scale(
    scale: 0.85 + 0.15 * _controller.value,
    child: dot,
  ),
);
```

### 7.4 Shutter Button

```dart
// Press: scale down to 0.88; release: bounce back to 1.0
GestureDetector(
  onTapDown: (_) => setState(() => _scale = 0.88),
  onTapUp: (_) => setState(() => _scale = 1.0),
  child: AnimatedScale(scale: _scale, duration: 120.ms, curve: Curves.easeOut, child: shutter),
)
```

### 7.5 Snap Timer Depletion

```dart
// Linear progress bar that depletes from full width to 0
TweenAnimationBuilder(
  tween: Tween(begin: 1.0, end: 0.0),
  duration: Duration(seconds: snapDuration),
  onEnd: () => _closeSnap(),
  builder: (_, value, __) => FractionallySizedBox(widthFactor: value, child: timerBar),
)
```

### 7.6 Couple Link Confirmation

```dart
// When partner confirms link: two avatars fly in from sides and merge with heart burst
// Implemented as a Lottie animation (lottie_flutter package, free Lottie files from LottieFiles)
Lottie.asset('assets/lottie/couple_link.json', width: 200, repeat: false)
```

---

## 8. Private Media Handling

This section describes how images, snaps, and voice notes are stored and displayed securely.

### 8.1 Upload Flow

```
User selects/captures media
         ↓
Compress image (flutter_image_compress)
  - Photos: max 1200px long edge, 80% quality
  - Profile pics: max 400px, 85% quality
         ↓
Generate AES-256 key + IV (client-side, dart:typed_data + encrypt package)
         ↓
Encrypt file bytes
         ↓
Upload encrypted bytes to API media storage
  Path:   "media/{coupleId}/{senderId}/{uuid}.enc"
         ↓
Store in DB: { storageRef, iv, mediaType, senderId, createdAt }
  NOTE: encryption KEY never stored server-side — derived per session
```

### 8.2 Download & Display Flow

```
Receive message/snap with storageRef + iv
         ↓
Fetch encrypted bytes from API media endpoint
  (Authorization: only authenticated partner in the same couple can fetch)
         ↓
Decrypt bytes using local AES key + iv
         ↓
Load into memory as Uint8List → display with Image.memory()
         ↓
NEVER write decrypted file to device storage unless user explicitly saves
```

### 8.3 Media Access Control

- API middleware verifies JWT and that `userId` is in `couples.user_ids` for the `coupleId` in the storage path.
- Media files are never served without a valid couple membership check.

### 8.4 Snap Auto-Delete

- Background job on the API server triggered on snap view event
- Job deletes the media file after `viewDuration` seconds
- PostgreSQL snap row marked `deleted = true` and cleaned up

### 8.5 Widget: Encrypted Image

```dart
class EncryptedImage extends StatefulWidget {
  final String storageRef;
  final String iv;
  final BoxFit fit;

  @override
  State createState() => _EncryptedImageState();
}

class _EncryptedImageState extends State<EncryptedImage> {
  Uint8List? _decryptedBytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 1. Fetch encrypted bytes from API media storage
    final encrypted = await MediaApiService.download(widget.storageRef);
    // 2. Decrypt with local key
    final decrypted = CryptoService.decrypt(encrypted, widget.iv);
    if (mounted) setState(() => _decryptedBytes = decrypted);
  }

  @override
  Widget build(BuildContext context) {
    if (_decryptedBytes == null) return ShimmerPlaceholder();
    return Image.memory(_decryptedBytes!, fit: widget.fit);
  }
}
```

---

## 9. Responsive Behaviour

All layouts target phones (360dp – 430dp width). Handle edge cases:

| Width | Layout adjustment |
|---|---|
| < 360dp | Reduce horizontal padding to 12px; hide partner status subtitle |
| 360–430dp | Default layout (all specs above) |
| > 430dp (large phones) | Increase card max-width, centre content at 430dp |
| Tablets (600dp+) | Side-by-side: sidebar (280dp) + main content panel |

---

## 10. Accessibility

- All interactive elements have `Semantics` labels
- Minimum tap target: 48×48dp (use `SizedBox` wrappers where needed)
- Color is never the sole indicator of state (e.g. unread badges have text count too)
- All images have `semanticLabel`
- Support OS font scale up to 1.5× without overflow (use flexible layouts)
- VoiceOver / TalkBack tested for chat, notes, and profile flows

---

## 11. Folder Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_spacing.dart
│   │   └── app_theme.dart
│   ├── router/
│   │   └── app_router.dart
│   └── utils/
│       ├── crypto_service.dart
│       └── image_compress_service.dart
│
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── profile_setup_screen.dart
│   │   │   └── couple_link_screen.dart
│   │   └── providers/auth_provider.dart
│   │
│   ├── chat/
│   │   ├── screens/
│   │   │   └── chat_screen.dart
│   │   ├── widgets/
│   │   │   ├── message_bubble.dart
│   │   │   ├── chat_input_bar.dart
│   │   │   ├── chat_theme_bar.dart
│   │   │   └── encrypted_image.dart
│   │   └── providers/chat_provider.dart
│   │
│   ├── snaps/
│   │   ├── screens/
│   │   │   ├── snaps_tab_screen.dart
│   │   │   ├── snap_camera_screen.dart
│   │   │   └── snap_view_screen.dart
│   │   └── providers/snaps_provider.dart
│   │
│   ├── music/
│   │   ├── screens/together_screen.dart
│   │   ├── widgets/music_player_card.dart
│   │   └── providers/music_provider.dart
│   │
│   ├── games/
│   │   ├── screens/
│   │   │   ├── games_hub_screen.dart
│   │   │   ├── chess_screen.dart
│   │   │   ├── tictactoe_screen.dart
│   │   │   ├── truth_dare_screen.dart
│   │   │   ├── love_quiz_screen.dart
│   │   │   └── memory_cards_screen.dart
│   │   └── providers/game_provider.dart
│   │
│   ├── notes/
│   │   ├── screens/
│   │   │   ├── notes_screen.dart
│   │   │   └── note_compose_screen.dart
│   │   ├── widgets/note_card.dart
│   │   └── providers/notes_provider.dart
│   │
│   └── profile/
│       ├── screens/
│       │   ├── profile_screen.dart
│       │   ├── profile_edit_screen.dart
│       │   └── settings_screen.dart
│       └── providers/profile_provider.dart
│
└── shared/
    └── widgets/
        ├── app_avatar.dart
        ├── app_button.dart
        ├── app_input.dart
        ├── app_badge.dart
        ├── shimmer_placeholder.dart
        ├── online_dot.dart
        └── drag_handle.dart
```

---

## 12. Key Flutter Packages Summary

| Package | Use |
|---|---|
| `google_fonts` | Syne + DM Sans fonts (free) |
| `flutter_animate` | All UI animations |
| `go_router` | Navigation |
| `riverpod` | State management |
| `dio` | REST API client |
| `web_socket_channel` | Realtime sync |
| `encrypt` | AES-256 client-side encryption |
| `flutter_secure_storage` | Secure key storage |
| `flutter_image_compress` | Image compression before upload |
| `just_audio` | Music playback |
| `camera` | Snap camera |
| `flutter_chess_board` | Chess game |
| `lottie` | Couple link + celebration animations |
| `hive_flutter` | Offline cache |
| `local_auth` | Biometric lock |
| `image_picker` | Gallery access |

---

*All fonts and Flutter packages are open-source. PostgreSQL and the API server can run on a small VPS or locally for development.*