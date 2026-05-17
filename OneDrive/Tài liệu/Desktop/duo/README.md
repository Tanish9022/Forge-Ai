# Atmos

Private couples app with encrypted chat, snaps, games, notes, shared music, and a PostgreSQL-backed Node API.

## Stack

- App: Flutter
- API: Node.js, Express, WebSockets
- Database: PostgreSQL
- External API: YouTube Data API

## Quick Start

```powershell
npm install
cmd /c npm run db:migrate
cmd /c npm run dev:api
```

In a second terminal:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

Use `http://10.0.2.2:3001/api` for Android emulator builds.

## Documentation

- Run and deploy: [docs/run-and-deploy.md](docs/run-and-deploy.md)
- Execution checklist: [docs/execution-checklist.md](docs/execution-checklist.md)
- Product requirements: [docs/prd.md](docs/prd.md)
- API details: [server/README.md](server/README.md)

## Environment

Copy `.env.example` to `.env` and set:

```env
PORT=3001
CLIENT_ORIGIN=http://localhost:5173
JWT_SECRET=change-this-to-a-long-random-secret
DATABASE_URL=postgres://postgres:YOUR_PASSWORD@localhost:5432/atmos
YOUTUBE_API_KEY=your-youtube-data-api-key
```
