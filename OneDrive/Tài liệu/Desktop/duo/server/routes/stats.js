import { Router } from 'express';
import { pool } from '../db/pool.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { coupleMiddleware } from '../middleware/coupleMiddleware.js';

const router = Router();
router.use(authMiddleware, coupleMiddleware);

router.get('/', async (req, res) => {
  try {
    const coupleId = req.coupleId;

    // Run aggregations in parallel
    const [messagesRes, snapsRes, notesRes, gamesRes] = await Promise.all([
      pool.query(`SELECT COUNT(*) as count FROM messages WHERE couple_id = $1`, [coupleId]),
      pool.query(`SELECT COUNT(*) as count FROM snaps WHERE couple_id = $1`, [coupleId]),
      pool.query(`SELECT COUNT(*) as count FROM notes WHERE couple_id = $1`, [coupleId]),
      pool.query(`SELECT COUNT(*) as count FROM game_state WHERE couple_id = $1`, [coupleId])
    ]);

    const stats = {
      totalMessages: parseInt(messagesRes.rows[0].count, 10),
      totalSnaps: parseInt(snapsRes.rows[0].count, 10),
      totalNotes: parseInt(notesRes.rows[0].count, 10),
      totalGamesPlayed: parseInt(gamesRes.rows[0].count, 10),
    };

    res.json({ stats });
  } catch (err) {
    console.error('stats aggregation error', err);
    res.status(500).json({ error: 'Failed to aggregate stats' });
  }
});

export default router;
