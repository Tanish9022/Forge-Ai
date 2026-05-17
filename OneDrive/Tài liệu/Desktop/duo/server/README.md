# Atmos API (Node/Express)

PostgreSQL-backed REST API + WebSocket for the Atmos Flutter app.

## Setup

```bash
# From repo root
npm install
npm run db:migrate
npm run dev:api
```

Requires `.env` at repo root (`PORT`, `JWT_SECRET`, `DATABASE_URL`, `YOUTUBE_API_KEY`, `CLIENT_ORIGIN`).

## Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/health` | — | `{ ok, db }` |
| POST | `/api/auth/signup` | — | `{ email, password, displayName }` → `{ token, user }` |
| POST | `/api/auth/login` | — | `{ email, password }` → `{ token, user }` |
| GET | `/api/auth/me` | JWT | Current user profile |
| POST | `/api/couples/code` | JWT | Generate 6-char invite code |
| POST | `/api/couples/link` | JWT | `{ code }` — link with partner |
| GET | `/api/couples/me` | JWT | Couple + partner info |
| GET | `/api/messages` | JWT + couple | List ciphertext messages |
| POST | `/api/messages` | JWT + couple | Send encrypted message |
| PATCH | `/api/messages/:id/status` | JWT + couple | `delivered` / `read` |
| GET | `/api/youtube/search?q=` | JWT | YouTube search proxy |

## WebSocket

Connect: `ws://127.0.0.1:3001/ws?token=<JWT>`

Events (server → client): `message:new`, `message:status`, `couple:linked`, `typing:start`, `typing:stop`

Client → server: `{ "type": "typing:start" }`, `{ "type": "typing:stop" }`

## Messages

Only **ciphertext** is stored (`encryptedContent` + `iv`). Never send plaintext to the API.
