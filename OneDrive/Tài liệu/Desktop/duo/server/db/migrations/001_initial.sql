-- Atmos initial schema (PRD §11) + couple invite codes

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- couples first (users.couple_id references this)
CREATE TABLE couples (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_ids   UUID[] NOT NULL CHECK (array_length(user_ids, 1) = 2),
  theme      TEXT DEFAULT 'rose',
  nickname   TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE users (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email            TEXT UNIQUE NOT NULL,
  password_hash    TEXT,
  display_name     TEXT,
  photo_url        TEXT,
  bio              TEXT,
  status           TEXT,
  partner_id       UUID REFERENCES users(id),
  couple_id        UUID REFERENCES couples(id),
  anniversary_date TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE couple_invites (
  code       CHAR(6) PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_couple_invites_user ON couple_invites(user_id);

CREATE TABLE messages (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id         UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
  encrypted_content TEXT NOT NULL,
  iv                TEXT NOT NULL,
  type              TEXT CHECK (type IN ('text', 'image', 'voice', 'gif')),
  sender_id         UUID NOT NULL REFERENCES users(id),
  status            TEXT CHECK (status IN ('sent', 'delivered', 'read')) DEFAULT 'sent',
  reply_to          UUID REFERENCES messages(id),
  created_at        TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_messages_couple_created ON messages(couple_id, created_at DESC);

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

CREATE TABLE notes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id  UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  type       TEXT CHECK (type IN ('routine', 'reminder', 'love', 'plan')),
  author_id  UUID NOT NULL REFERENCES users(id),
  pinned     BOOLEAN DEFAULT false,
  due_date   TIMESTAMPTZ,
  reactions  JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE game_state (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id    UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
  game         TEXT NOT NULL,
  state        JSONB NOT NULL,
  current_turn UUID REFERENCES users(id),
  scores       JSONB DEFAULT '{}',
  updated_at   TIMESTAMPTZ DEFAULT now()
);

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
