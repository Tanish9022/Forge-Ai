import { Router } from 'express';
import { z } from 'zod';
import { pool } from '../db/pool.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { coupleMiddleware } from '../middleware/coupleMiddleware.js';
import { broadcastToCouple } from '../ws/hub.js';

const router = Router();
router.use(authMiddleware, coupleMiddleware);

router.get('/:game', async (req, res) => {
  const { game } = req.params;
  
  let { rows } = await pool.query(
    `SELECT id, couple_id, game, state, current_turn, scores, updated_at
     FROM game_state WHERE couple_id = $1 AND game = $2`,
    [req.coupleId, game]
  );

  if (rows.length === 0) {
    // Initialize default state
    const defaultState = game === 'chess' ? { fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1' } : {};
    
    const insertRes = await pool.query(
      `INSERT INTO game_state (couple_id, game, state)
       VALUES ($1, $2, $3)
       RETURNING id, couple_id, game, state, current_turn, scores, updated_at`,
      [req.coupleId, game, defaultState]
    );
    rows = insertRes.rows;
  }

  res.json({ gameState: rows[0] });
});

const updateSchema = z.object({
  state: z.any(),
  currentTurn: z.string().uuid().optional(),
});

router.patch('/:game', async (req, res) => {
  const { game } = req.params;
  const parsed = updateSchema.safeParse(req.body);
  
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { state, currentTurn } = parsed.data;

  const { rows } = await pool.query(
    `UPDATE game_state 
     SET state = $1, current_turn = $2, updated_at = now()
     WHERE couple_id = $3 AND game = $4
     RETURNING id, couple_id, game, state, current_turn, scores, updated_at`,
    [state, currentTurn || null, req.coupleId, game]
  );

  if (rows.length === 0) {
     return res.status(404).json({ error: 'Game not found' });
  }

  const gameState = rows[0];
  
  broadcastToCouple(req.coupleId, {
    type: 'game:update',
    game,
    gameState,
  });

  res.json({ gameState });
});

export default router;
