-- Align tables with the Flutter feature contracts.

ALTER TABLE notes
  ADD COLUMN IF NOT EXISTS encrypted_title TEXT,
  ADD COLUMN IF NOT EXISTS title_iv TEXT,
  ADD COLUMN IF NOT EXISTS encrypted_content TEXT,
  ADD COLUMN IF NOT EXISTS content_iv TEXT,
  ADD COLUMN IF NOT EXISTS color TEXT DEFAULT 'rose',
  ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

ALTER TABLE notes
  ALTER COLUMN content DROP NOT NULL;

UPDATE notes
SET
  encrypted_title = COALESCE(encrypted_title, 'legacy'),
  title_iv = COALESCE(title_iv, 'legacy'),
  encrypted_content = COALESCE(encrypted_content, content, 'legacy'),
  content_iv = COALESCE(content_iv, 'legacy'),
  is_pinned = COALESCE(is_pinned, pinned, false),
  updated_at = COALESCE(updated_at, created_at, now())
WHERE encrypted_title IS NULL
   OR title_iv IS NULL
   OR encrypted_content IS NULL
   OR content_iv IS NULL
   OR updated_at IS NULL;

ALTER TABLE couples
  ADD COLUMN IF NOT EXISTS partner_nicknames JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS snap_streak INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS snap_streak_updated_on DATE;

ALTER TABLE snaps
  ADD COLUMN IF NOT EXISTS saved_by UUID[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
