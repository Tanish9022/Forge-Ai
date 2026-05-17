import { Router } from 'express';
import { z } from 'zod';
import { pool } from '../db/pool.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { coupleMiddleware } from '../middleware/coupleMiddleware.js';
import { broadcastToCouple } from '../ws/hub.js';

const router = Router();
router.use(authMiddleware, coupleMiddleware);

router.get('/', async (req, res) => {
  let { rows } = await pool.query(
    `SELECT couple_id, track_id, track_title, track_artist, is_playing, position, updated_at, updated_by, queue
     FROM music_sessions WHERE couple_id = $1`,
    [req.coupleId]
  );

  if (rows.length === 0) {
    const insertRes = await pool.query(
      `INSERT INTO music_sessions (couple_id)
       VALUES ($1)
       RETURNING couple_id, track_id, track_title, track_artist, is_playing, position, updated_at, updated_by, queue`,
      [req.coupleId]
    );
    rows = insertRes.rows;
  }

  res.json({ musicSession: rows[0] });
});

const updateSchema = z.object({
  trackId: z.string().nullable().optional(),
  trackTitle: z.string().nullable().optional(),
  trackArtist: z.string().nullable().optional(),
  isPlaying: z.boolean().optional(),
  position: z.number().optional(),
  queue: z.array(z.any()).optional(),
});

router.patch('/', async (req, res) => {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { trackId, trackTitle, trackArtist, isPlaying, position, queue } = parsed.data;
  
  // Build dynamic update query
  const updates = [];
  const params = [];
  let paramCount = 1;

  if (trackId !== undefined) {
    updates.push(`track_id = $${paramCount++}`);
    params.push(trackId);
  }
  if (trackTitle !== undefined) {
    updates.push(`track_title = $${paramCount++}`);
    params.push(trackTitle);
  }
  if (trackArtist !== undefined) {
    updates.push(`track_artist = $${paramCount++}`);
    params.push(trackArtist);
  }
  if (isPlaying !== undefined) {
    updates.push(`is_playing = $${paramCount++}`);
    params.push(isPlaying);
  }
  if (position !== undefined) {
    updates.push(`position = $${paramCount++}`);
    params.push(position);
  }
  if (queue !== undefined) {
    updates.push(`queue = $${paramCount++}`);
    params.push(JSON.stringify(queue));
  }

  if (updates.length === 0) {
    return res.status(400).json({ error: 'No fields to update' });
  }

  updates.push(`updated_at = now()`);
  updates.push(`updated_by = $${paramCount++}`);
  params.push(req.userId);

  params.push(req.coupleId); // Last param is coupleId for WHERE clause

  const query = `
    UPDATE music_sessions 
    SET ${updates.join(', ')}
    WHERE couple_id = $${paramCount}
    RETURNING couple_id, track_id, track_title, track_artist, is_playing, position, updated_at, updated_by, queue
  `;

  const { rows } = await pool.query(query, params);
  
  if (rows.length === 0) {
    // Session might not exist yet, let's create it
    const insertRes = await pool.query(
      `INSERT INTO music_sessions (couple_id) VALUES ($1) RETURNING *`,
      [req.coupleId]
    );
    // Then re-run the update
    const retryRes = await pool.query(query, params);
    rows[0] = retryRes.rows[0];
  }

  const musicSession = rows[0];

  broadcastToCouple(req.coupleId, {
    type: 'music:update',
    musicSession,
  });

  res.json({ musicSession });
});

export default router;
