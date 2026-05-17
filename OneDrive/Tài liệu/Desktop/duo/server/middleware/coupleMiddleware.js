import { pool } from '../db/pool.js';

/** Requires authMiddleware first. Sets req.coupleId and req.couple. */
export async function coupleMiddleware(req, res, next) {
  if (!req.userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const { rows } = await pool.query(
    `SELECT c.id, c.user_ids, c.theme, c.nickname, c.created_at
     FROM couples c
     INNER JOIN users u ON u.couple_id = c.id
     WHERE u.id = $1`,
    [req.userId]
  );

  if (rows.length === 0) {
    return res.status(403).json({ error: 'Not linked to a couple' });
  }

  const couple = rows[0];
  if (!couple.user_ids.includes(req.userId)) {
    return res.status(403).json({ error: 'Not a member of this couple' });
  }

  req.coupleId = couple.id;
  req.couple = {
    id: couple.id,
    userIds: couple.user_ids,
    theme: couple.theme,
    nickname: couple.nickname,
    createdAt: couple.created_at,
  };
  next();
}
