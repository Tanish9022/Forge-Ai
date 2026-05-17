import { Router } from 'express';
import { z } from 'zod';
import { pool } from '../db/pool.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { broadcastToCouple } from '../ws/hub.js';

const router = Router();
router.use(authMiddleware);

const INVITE_TTL_MS = 24 * 60 * 60 * 1000;
const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function generateCode() {
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return code;
}

async function createUniqueCode(client, userId) {
  const existing = await client.query(
    `SELECT code, expires_at FROM couple_invites
     WHERE user_id = $1 AND expires_at > now()
     ORDER BY created_at DESC
     LIMIT 1`,
    [userId]
  );

  if (existing.rows[0]) {
    return {
      code: existing.rows[0].code.trim(),
      expiresAt: existing.rows[0].expires_at,
    };
  }

  for (let attempt = 0; attempt < 10; attempt++) {
    const code = generateCode();
    const expiresAt = new Date(Date.now() + INVITE_TTL_MS);
    try {
      await client.query(
        'DELETE FROM couple_invites WHERE user_id = $1',
        [userId]
      );
      await client.query(
        `INSERT INTO couple_invites (code, user_id, expires_at)
         VALUES ($1, $2, $3)`,
        [code, userId, expiresAt]
      );
      return { code, expiresAt };
    } catch (err) {
      if (err.code === '23505') continue;
      throw err;
    }
  }
  throw new Error('Could not generate unique invite code');
}

router.post('/code', async (req, res) => {
  if (req.user.coupleId) {
    return res.status(400).json({ error: 'Already linked to a couple' });
  }

  const client = await pool.connect();
  try {
    const { code, expiresAt } = await createUniqueCode(client, req.userId);
    res.json({ code, expiresAt });
  } catch (err) {
    console.error('couple code error', err);
    res.status(500).json({ error: 'Failed to generate invite code' });
  } finally {
    client.release();
  }
});

router.get('/code', async (req, res) => {
  if (req.user.coupleId) {
    return res.status(400).json({ error: 'Already linked to a couple' });
  }

  const client = await pool.connect();
  try {
    const { code, expiresAt } = await createUniqueCode(client, req.userId);
    res.json({ code, expiresAt });
  } catch (err) {
    console.error('couple code get error', err);
    res.status(500).json({ error: 'Failed to load invite code' });
  } finally {
    client.release();
  }
});

const linkSchema = z.object({
  code: z.string().length(6).transform((c) => c.toUpperCase()),
});

router.post('/link', async (req, res) => {
  const parsed = linkSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  if (req.user.coupleId) {
    return res.status(400).json({ error: 'Already linked to a couple' });
  }

  const { code } = parsed.data;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const inviteResult = await client.query(
      `SELECT user_id, expires_at FROM couple_invites
       WHERE code = $1 FOR UPDATE`,
      [code]
    );

    if (inviteResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Invalid or expired code' });
    }

    const invite = inviteResult.rows[0];
    if (new Date(invite.expires_at) < new Date()) {
      await client.query('DELETE FROM couple_invites WHERE code = $1', [code]);
      await client.query('COMMIT');
      return res.status(410).json({ error: 'Invite code expired' });
    }

    const inviterId = invite.user_id;
    if (inviterId === req.userId) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Cannot link with yourself' });
    }

    const inviterCheck = await client.query(
      'SELECT couple_id FROM users WHERE id = $1',
      [inviterId]
    );
    if (inviterCheck.rows[0]?.couple_id) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Inviter is already linked' });
    }

    const coupleResult = await client.query(
      `INSERT INTO couples (user_ids) VALUES ($1::uuid[])
       RETURNING id, user_ids, theme, nickname, created_at`,
      [[inviterId, req.userId]]
    );
    const couple = coupleResult.rows[0];

    await client.query(
      `UPDATE users SET couple_id = $1, partner_id = $2 WHERE id = $3`,
      [couple.id, req.userId, inviterId]
    );
    await client.query(
      `UPDATE users SET couple_id = $1, partner_id = $2 WHERE id = $3`,
      [couple.id, inviterId, req.userId]
    );
    await client.query('DELETE FROM couple_invites WHERE code = $1', [code]);
    await client.query('DELETE FROM couple_invites WHERE user_id = $1', [
      inviterId,
    ]);

    await client.query('COMMIT');

    const payload = {
      id: couple.id,
      userIds: couple.user_ids,
      theme: couple.theme,
      nickname: couple.nickname,
      createdAt: couple.created_at,
    };

    broadcastToCouple(couple.id, { type: 'couple:linked', couple: payload });

    res.json({ couple: payload });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('couple link error', err);
    res.status(500).json({ error: 'Failed to link couple' });
  } finally {
    client.release();
  }
});

router.get('/me', async (req, res) => {
  if (!req.user.coupleId) {
    return res.json({ couple: null });
  }

  const { rows } = await pool.query(
      `SELECT id, user_ids, theme, nickname, partner_nicknames, snap_streak, snap_streak_updated_on, created_at
     FROM couples WHERE id = $1`,
    [req.user.coupleId]
  );

  if (rows.length === 0) {
    return res.json({ couple: null });
  }

  const c = rows[0];
  const partnerId = c.user_ids.find((id) => id !== req.userId);
  let partner = null;
  if (partnerId) {
    const partnerRows = await pool.query(
      `SELECT id, email, display_name, photo_url, status
       FROM users WHERE id = $1`,
      [partnerId]
    );
    if (partnerRows.rows[0]) {
      const p = partnerRows.rows[0];
      partner = {
        id: p.id,
        email: p.email,
        displayName: p.display_name,
        photoUrl: p.photo_url,
        status: p.status,
      };
    }
  }

  res.json({
    couple: {
      id: c.id,
      userIds: c.user_ids,
      theme: c.theme,
      nickname: c.nickname,
      partnerNickname: c.partner_nicknames?.[req.userId] || null,
      snapStreak: c.snap_streak || 0,
      snapStreakUpdatedOn: c.snap_streak_updated_on,
      createdAt: c.created_at,
      partner,
    },
  });
});

const partnerNicknameSchema = z.object({
  nickname: z.string().trim().max(40).nullable(),
});

router.patch('/partner-nickname', async (req, res) => {
  if (!req.user.coupleId) {
    return res.status(400).json({ error: 'Not linked to a couple' });
  }

  const parsed = partnerNicknameSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const nickname = parsed.data.nickname || null;
  const { rows } = await pool.query(
    `UPDATE couples
     SET partner_nicknames = CASE
       WHEN $1::text IS NULL THEN partner_nicknames - $2::text
       ELSE jsonb_set(COALESCE(partner_nicknames, '{}'::jsonb), ARRAY[$2::text], to_jsonb($1::text), true)
     END
     WHERE id = $3
     RETURNING id, user_ids, theme, nickname, partner_nicknames, snap_streak, snap_streak_updated_on, created_at`,
    [nickname, req.userId, req.user.coupleId]
  );

  if (rows.length === 0) {
    return res.status(404).json({ error: 'Couple not found' });
  }

  const c = rows[0];
  const couplePayload = {
    id: c.id,
    userIds: c.user_ids,
    theme: c.theme,
    nickname: c.nickname,
    partnerNicknames: c.partner_nicknames || {},
    snapStreak: c.snap_streak || 0,
    snapStreakUpdatedOn: c.snap_streak_updated_on,
    createdAt: c.created_at,
  };

  broadcastToCouple(req.user.coupleId, {
    type: 'couple:update',
    couple: couplePayload,
  });

  res.json({
    couple: {
      ...couplePayload,
      partnerNickname: c.partner_nicknames?.[req.userId] || null,
    },
  });
});

const themeSchema = z.object({
  theme: z.string().min(1),
});

router.patch('/theme', async (req, res) => {
  if (!req.user.coupleId) {
    return res.status(400).json({ error: 'Not linked to a couple' });
  }

  const parsed = themeSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { theme } = parsed.data;

  try {
    const { rows } = await pool.query(
      `UPDATE couples SET theme = $1 WHERE id = $2 RETURNING id, user_ids, theme, nickname, created_at`,
      [theme, req.user.coupleId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Couple not found' });
    }

    const c = rows[0];
    const couplePayload = {
      id: c.id,
      userIds: c.user_ids,
      theme: c.theme,
      nickname: c.nickname,
      createdAt: c.created_at,
    };

    broadcastToCouple(req.user.coupleId, {
      type: 'couple:update',
      couple: couplePayload,
    });

    res.json({ couple: couplePayload });
  } catch (err) {
    console.error('couple theme update error', err);
    res.status(500).json({ error: 'Failed to update theme' });
  }
});

export default router;
