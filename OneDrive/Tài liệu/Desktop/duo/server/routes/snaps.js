import { Router } from 'express';
import { z } from 'zod';
import { pool } from '../db/pool.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { coupleMiddleware } from '../middleware/coupleMiddleware.js';
import { broadcastToCouple } from '../ws/hub.js';

const router = Router();
router.use(authMiddleware, coupleMiddleware);

function toSnap(row) {
  return {
    id: row.id,
    coupleId: row.couple_id,
    storageRef: row.storage_ref,
    senderId: row.sender_id,
    duration: row.duration,
    viewed: row.viewed,
    savedBy: row.saved_by || [],
    deletedAt: row.deleted_at,
    createdAt: row.created_at,
    expiresAt: row.expires_at,
  };
}

async function bumpSnapStreak(db, coupleId) {
  const { rows } = await db.query(
    `UPDATE couples
     SET snap_streak = CASE
         WHEN snap_streak_updated_on = CURRENT_DATE THEN snap_streak
         WHEN snap_streak_updated_on = CURRENT_DATE - INTERVAL '1 day' THEN snap_streak + 1
         ELSE 1
       END,
       snap_streak_updated_on = CURRENT_DATE
     WHERE id = $1
     RETURNING snap_streak, snap_streak_updated_on`,
    [coupleId]
  );

  return {
    snapStreak: rows[0]?.snap_streak || 0,
    snapStreakUpdatedOn: rows[0]?.snap_streak_updated_on || null,
  };
}

router.get('/', async (req, res) => {
  const [snapsResult, coupleResult] = await Promise.all([
    pool.query(
      `SELECT id, couple_id, storage_ref, sender_id, duration, viewed, saved_by, deleted_at, created_at, expires_at
     FROM snaps
     WHERE couple_id = $1 AND deleted_at IS NULL
     ORDER BY created_at DESC`,
      [req.coupleId]
    ),
    pool.query(
      `SELECT snap_streak, snap_streak_updated_on FROM couples WHERE id = $1`,
      [req.coupleId]
    ),
  ]);
  
  res.json({
    snaps: snapsResult.rows.map(toSnap),
    streak: {
      count: coupleResult.rows[0]?.snap_streak || 0,
      updatedOn: coupleResult.rows[0]?.snap_streak_updated_on || null,
    },
  });
});

const createSchema = z.object({
  storageRef: z.string().min(1),
  duration: z.number().int().positive().nullable(), // Null means infinite
});

router.post('/', async (req, res) => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { storageRef, duration } = parsed.data;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
    `INSERT INTO snaps (couple_id, storage_ref, sender_id, duration)
     VALUES ($1, $2, $3, $4)
     RETURNING id, couple_id, storage_ref, sender_id, duration, viewed, saved_by, deleted_at, created_at, expires_at`,
      [req.coupleId, storageRef, req.userId, duration]
    );

    const streak = await bumpSnapStreak(client, req.coupleId);
    await client.query('COMMIT');

    const snap = toSnap(rows[0]);
  
    broadcastToCouple(req.coupleId, {
      type: 'snap:new',
      snap,
      streak,
    });

    res.status(201).json({ snap, streak });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('snap create error', err);
    res.status(500).json({ error: 'Failed to create snap' });
  } finally {
    client.release();
  }
});

router.post('/:id/view', async (req, res) => {
  const { id } = req.params;

  // We only allow viewing if not viewed yet
  // If it has a duration, set expires_at = now() + duration seconds
  
  // First get the snap
  const getRes = await pool.query(
    `SELECT duration, viewed, sender_id FROM snaps WHERE id = $1 AND couple_id = $2 AND deleted_at IS NULL`,
    [id, req.coupleId]
  );
  
  if (getRes.rows.length === 0) {
    return res.status(404).json({ error: 'Snap not found' });
  }
  
  const snapData = getRes.rows[0];
  
  if (snapData.sender_id === req.userId) {
     return res.status(400).json({ error: 'Cannot view your own snap' });
  }
  
  if (snapData.viewed) {
    return res.status(400).json({ error: 'Snap already viewed' });
  }
  
  let expiresAtQuery = 'NULL';
  if (snapData.duration) {
    expiresAtQuery = `now() + interval '${snapData.duration} seconds'`;
  }
  
  const { rows } = await pool.query(
    `UPDATE snaps
     SET viewed = true, expires_at = ${expiresAtQuery}
     WHERE id = $1 AND couple_id = $2
     RETURNING id, couple_id, storage_ref, sender_id, duration, viewed, saved_by, deleted_at, created_at, expires_at`,
    [id, req.coupleId]
  );
  
  const snap = toSnap(rows[0]);
  
  broadcastToCouple(req.coupleId, {
    type: 'snap:update',
    snap,
  });
  
  res.json({ snap });
});

router.patch('/:id/save', async (req, res) => {
  const { id } = req.params;
  const { rows } = await pool.query(
    `UPDATE snaps
     SET saved_by = CASE
       WHEN $1 = ANY(saved_by) THEN array_remove(saved_by, $1)
       ELSE array_append(saved_by, $1)
     END
     WHERE id = $2 AND couple_id = $3 AND deleted_at IS NULL
     RETURNING id, couple_id, storage_ref, sender_id, duration, viewed, saved_by, deleted_at, created_at, expires_at`,
    [req.userId, id, req.coupleId]
  );

  if (rows.length === 0) {
    return res.status(404).json({ error: 'Snap not found' });
  }

  const snap = toSnap(rows[0]);
  broadcastToCouple(req.coupleId, { type: 'snap:update', snap });
  res.json({ snap });
});

router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  const { rows } = await pool.query(
    `UPDATE snaps
     SET deleted_at = now()
     WHERE id = $1 AND couple_id = $2 AND deleted_at IS NULL
     RETURNING id`,
    [id, req.coupleId]
  );

  if (rows.length === 0) {
    return res.status(404).json({ error: 'Snap not found' });
  }

  broadcastToCouple(req.coupleId, { type: 'snap:delete', snapId: id });
  res.json({ success: true });
});

export default router;
