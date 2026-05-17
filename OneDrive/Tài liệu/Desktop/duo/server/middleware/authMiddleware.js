import { verifyToken } from '../utils/tokens.js';
import { pool } from '../db/pool.js';
import { toPublicUser } from '../utils/user.js';

export async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid authorization' });
  }

  const token = header.slice(7);
  try {
    const payload = verifyToken(token);
    const { rows } = await pool.query(
      `SELECT id, email, display_name, photo_url, bio, status,
              partner_id, couple_id, anniversary_date, created_at
       FROM users WHERE id = $1`,
      [payload.userId]
    );
    if (rows.length === 0) {
      return res.status(401).json({ error: 'User not found' });
    }
    req.user = toPublicUser(rows[0]);
    req.userId = rows[0].id;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
