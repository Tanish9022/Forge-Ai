# Run and Deploy Atmos

Atmos is a Flutter app backed by a Node/Express API, PostgreSQL, WebSockets, and the YouTube Data API.

## Local prerequisites

- Flutter SDK 3.x with Android Studio or Xcode for mobile builds
- Node.js 18+
- PostgreSQL 14+
- A YouTube Data API key

## Environment

Create `.env` in the repo root:

```env
PORT=3001
CLIENT_ORIGIN=http://localhost:5173,http://localhost:3000,http://127.0.0.1:3000
JWT_SECRET=replace-with-a-long-random-secret
DATABASE_URL=postgres://postgres:YOUR_PASSWORD@localhost:5432/atmos
YOUTUBE_API_KEY=your-youtube-data-api-key
```

For Android emulator builds, use `http://10.0.2.2:3001/api` as the Flutter API URL. For iOS simulator, desktop, and web, use `http://127.0.0.1:3001/api`.

## Run locally

From the repo root:

```powershell
npm install
cmd /c npm run db:migrate
cmd /c npm run dev:api
```

The API runs at `http://127.0.0.1:3001/api`.

In a second terminal, run Flutter:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

Android emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001/api
```

## Build

Web build:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://YOUR_API_HOST/api
```

If Flutter fails while writing icon font outputs from a OneDrive or non-ASCII path, use:

```powershell
flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL=https://YOUR_API_HOST/api
```

Android APK:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_API_HOST/api
```

Android App Bundle for Play Console:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://YOUR_API_HOST/api
```

iOS release build, from macOS:

```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://YOUR_API_HOST/api
```

## Recommended deployment

Use managed services for production:

- API: Render, Railway, Fly.io, or Google Cloud Run
- PostgreSQL: Neon, Supabase Postgres, Railway Postgres, Render Postgres, or Cloud SQL
- Flutter web: Firebase Hosting, Netlify, Vercel, or Cloudflare Pages
- Android: Google Play Console
- iOS: App Store Connect

The simplest production setup is:

1. Neon for PostgreSQL.
2. Render Web Service for the Node API.
3. Firebase Hosting or Netlify for Flutter web.
4. Play Console and App Store Connect for mobile releases.

## Deploy the API

Create the hosted PostgreSQL database first, then set these API environment variables on the host:

```env
PORT=3001
CLIENT_ORIGIN=https://YOUR_WEB_HOST
JWT_SECRET=replace-with-a-long-random-secret
DATABASE_URL=postgres://USER:PASSWORD@HOST:5432/DB_NAME?sslmode=require
YOUTUBE_API_KEY=your-youtube-data-api-key
```

Use these commands in the API host:

```bash
npm install
npm run db:migrate
npm run start:api
```

After deploy, verify:

```bash
curl https://YOUR_API_HOST/api/health
```

Expected healthy response:

```json
{ "ok": true, "db": "connected" }
```

## Deploy Flutter web

Build with the deployed API URL:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://YOUR_API_HOST/api
```

Deploy the generated `build/web` directory to Firebase Hosting, Netlify, Vercel, or Cloudflare Pages.

For single-page app routing, configure all routes to serve `index.html`.

Flutter may print WebAssembly dry-run warnings for `flutter_secure_storage_web`. The standard JavaScript web build still works; those warnings only mean the current dependency set is not ready for Flutter's Wasm web target.

## Production checks

- Use HTTPS for the API and web app.
- Set `CLIENT_ORIGIN` to the exact production web origin, not `*`.
- Use a strong `JWT_SECRET`.
- Keep `YOUTUBE_API_KEY` server-side only.
- Run migrations against the production database before opening the app.
- Confirm WebSocket support on the API host.
- Complete the security audit in `docs/security-audit.md` before public launch.
