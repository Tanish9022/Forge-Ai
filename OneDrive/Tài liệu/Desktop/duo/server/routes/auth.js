import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { pool } from '../db/pool.js';
import { signToken } from '../utils/tokens.js';
import { toPublicUser } from '../utils/user.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = Router();

const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  displayName: z.string().min(1).max(100),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

router.post('/signup', async (req, res) => {
  const parsed = signupSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { email, password, displayName } = parsed.data;
  const passwordHash = await bcrypt.hash(password, 12);

  try {
    const { rows } = await pool.query(
      `INSERT INTO users (email, password_hash, display_name)
       VALUES ($1, $2, $3)
       RETURNING id, email, display_name, photo_url, bio, status,
                 partner_id, couple_id, anniversary_date, created_at`,
      [email.toLowerCase(), passwordHash, displayName]
    );
    const user = toPublicUser(rows[0]);
    const token = signToken(rows[0].id);
    res.status(201).json({ token, user });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Email already registered' });
    }
    console.error('signup error', err);
    res.status(500).json({ error: 'Signup failed' });
  }
});

router.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { email, password } = parsed.data;

  const { rows } = await pool.query(
    `SELECT id, email, password_hash, display_name, photo_url, bio, status,
            partner_id, couple_id, anniversary_date, created_at
     FROM users WHERE email = $1`,
    [email.toLowerCase()]
  );

  if (rows.length === 0) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const row = rows[0];
  if (!row.password_hash) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const valid = await bcrypt.compare(password, row.password_hash);
  if (!valid) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const user = toPublicUser(row);
  const token = signToken(row.id);
  res.json({ token, user });
});

router.get('/me', authMiddleware, (req, res) => {
  res.json({ user: req.user });
});

router.delete('/me', authMiddleware, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // If part of a couple, handle partner unlinking
    if (req.user.coupleId) {
      // Set partner's couple_id and partner_id to null
      await client.query(
        `UPDATE users SET couple_id = NULL, partner_id = NULL WHERE partner_id = $1`,
        [req.userId]
      );
      // We also could delete the couple and all their messages/snaps/notes here
      // depending on the policy. For a "full data purge", let's delete the couple.
      // Postgres CASCADE should handle messages/snaps/notes if set up, or we do it manually.
      // Based on typical schema, let's delete the couple itself.
      await client.query(`DELETE FROM couples WHERE id = $1`, [req.user.coupleId]);
    }
    
    await client.query(`DELETE FROM users WHERE id = $1`, [req.userId]);
    await client.query('COMMIT');
    
    res.json({ success: true });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Account deletion error', err);
    res.status(500).json({ error: 'Failed to delete account' });
  } finally {
    client.release();
  }
});

export default router;
