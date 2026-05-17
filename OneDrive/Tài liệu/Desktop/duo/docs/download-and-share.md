# Download and Share Atmos

This guide explains how to run, test, and share the Atmos app with a partner.

Atmos has two parts:

- **Flutter app** — iOS and Android client (optional `flutter run -d chrome` for web during development).
- **Backend** — Node/Express API connected to PostgreSQL.

Important: a built APK or installed app is not enough on its own. The API server and database must be running and reachable from the device.

---

## Prerequisites

Install on your development machine:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Node.js 18 or newer
- PostgreSQL 14 or newer
- Android Studio (for Android builds) and/or Xcode (for iOS, macOS only)

Verify Flutter:

```powershell
flutter doctor
```

---

## Environment Setup

Copy `.env.example` to `.env` in the project root, then edit:

```env
PORT=3001
CLIENT_ORIGIN=*
JWT_SECRET=change-this-to-a-long-random-secret
DATABASE_URL=postgres://postgres:YOUR_PASSWORD@localhost:5432/atmos
YOUTUBE_API_KEY=your-youtube-data-api-key
```

- `YOUTUBE_API_KEY` is **server-only** — never embed it in the Flutter app.
- The Flutter app receives the API URL at build/run time via `--dart-define` (see below).

### Create the database

If `atmos` does not exist yet:

```powershell
$env:PGPASSWORD = "YOUR_PASSWORD"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -c "CREATE DATABASE atmos;"
```

Adjust the PostgreSQL path if your version differs.

---

## Local Development

### 1. Install API dependencies

```powershell
npm install
```

(Run from the project root once the API package exists.)

### 2. Start the backend

Terminal 1:

```powershell
npm run dev:api
```

API base URL (local):

```text
http://localhost:3001/api
```

### 3. Run the Flutter app

Terminal 2 — use your machine's LAN IP so a physical phone on the same Wi-Fi can reach the API:

```powershell
# Find your IPv4 address
ipconfig

# Example: 192.168.1.25
flutter run --dart-define=API_BASE_URL=http://192.168.1.25:3001/api
```

For an emulator on the same machine:

```powershell
# Android emulator → host machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001/api

# iOS simulator (macOS)
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

Optional web preview during UI work:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

---

## Option 1: Test on the Same Wi-Fi (Two Phones)

1. Start the API on your computer (`npm run dev:api`).
2. Allow Node.js through Windows Firewall (private network).
3. Build/run Flutter on each phone with your computer's IP:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:3001/api
```

4. Both devices must be on the same Wi-Fi network.

Note: plain `http` may be blocked on some Android versions. For reliable device testing, host the API with HTTPS.

---

## Option 2: Share the Source Code

1. Zip the project folder (exclude `build/`, `.dart_tool/`, `node_modules/`).
2. Send via Drive, OneDrive, etc.
3. Your friend installs Flutter, Node.js, and PostgreSQL.
4. They copy `.env.example` → `.env`, create the `atmos` database, then:

```powershell
npm install
npm run dev:api
```

In another terminal:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

---

## Option 3: Build and Share an Android APK

### 1. Set the API URL for release builds

`localhost` will not work on a physical phone — use your deployed API or LAN IP:

```powershell
flutter build apk --dart-define=API_BASE_URL=https://your-api-domain.com/api
```

For a debug APK on the same Wi-Fi:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:3001/api
```

### 2. Locate the APK

Debug:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

Release:

```text
build\app\outputs\flutter-apk\app-release.apk
```

### 3. Share the APK

Send the file to your friend. They may need to enable **Install unknown apps** on Android.

### 4. Backend must stay online

The APK only works while the API and PostgreSQL are running and reachable.

---

## Option 4: iOS Build (macOS only)

```bash
flutter build ios --dart-define=API_BASE_URL=https://your-api-domain.com/api
```

Open `ios/Runner.xcworkspace` in Xcode to archive and distribute via TestFlight or the App Store.

---

## Best Way to Share With a Partner

**Quick same-room test:**

1. Run API on your computer.
2. Run Flutter on both phones with `--dart-define=API_BASE_URL=http://YOUR_IP:3001/api`.

**Real-world use:**

1. Deploy API + PostgreSQL with HTTPS.
2. Build release APK/IPA with `--dart-define=API_BASE_URL=https://your-api-domain.com/api`.
3. Share the install file or publish to stores.

---

## Troubleshooting

**App cannot connect to API**

- Do not use `localhost` on a physical device — use your LAN IP or HTTPS domain.
- Confirm the API is running on port `3001`.
- Check Windows Firewall allows Node.js on private networks.
- On Android, cleartext HTTP may be blocked; prefer HTTPS for production.

**Login or signup fails**

- Verify `DATABASE_URL` and that PostgreSQL is running.
- Confirm the `atmos` database exists.
- Check API logs for migration or connection errors.

**YouTube search / music fails**

- Verify `YOUTUBE_API_KEY` is set in server `.env` only.
- Confirm the API proxies YouTube requests (key must not ship in the Flutter app).

**Flutter build errors**

- Run `flutter doctor` and fix reported issues.
- Run `flutter pub get` after pulling new code.
