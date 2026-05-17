# Atmos Security Audit Checklist

## Storage Model

- Text messages are encrypted in the browser with libsodium `crypto_box_easy`.
- Photo messages are converted to a data URL in the browser, then encrypted with the same message path.
- Snaps are encrypted in the browser before upload and are only returned to the intended recipient once.
- The API stores `ciphertext`, `nonce`, message metadata, sender/recipient IDs, and receipt timestamps. It does not receive plaintext message, photo, or snap content.

## Retention Rules

- Regular encrypted messages are deleted after 30 days.
- Opened snaps are scrubbed immediately after the recipient receives the encrypted payload.
- Unopened snaps expire after 24 hours and are scrubbed during the retention purge.
- Snap events keep only event metadata: snap ID, event type, actor ID, and timestamp.

## Audit Endpoint

Run `GET /api/audit/ciphertext` while authenticated.

Expected result:

```json
{
  "ok": true,
  "messageViolations": 0,
  "snapViolations": 0,
  "staleMessageViolations": 0,
  "retainedOpenedSnapViolations": 0,
  "expiredSnapViolations": 0
}
```

## Remaining Production Requirements

- Rotate any API keys that were pasted into chat or logs.
- Use HTTPS only in production.
- Keep `JWT_SECRET`, `DATABASE_URL`, and `YOUTUBE_API_KEY` in host-managed secrets.
- Use Postgres backups with restricted access.
- Add rate limiting before public launch.

