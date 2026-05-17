import { Router } from 'express';
import { z } from 'zod';
import { pool } from '../db/pool.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { coupleMiddleware } from '../middleware/coupleMiddleware.js';
import { broadcastToCouple } from '../ws/hub.js';

const router = Router();
router.use(authMiddleware, coupleMiddleware);

function toNote(row) {
  return {
    id: row.id,
    coupleId: row.couple_id,
    authorId: row.author_id,
    encryptedTitle: row.encrypted_title,
    titleIv: row.title_iv,
    encryptedContent: row.encrypted_content,
    contentIv: row.content_iv,
    color: row.color,
    isPinned: row.is_pinned,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

router.get('/', async (req, res) => {
  const { rows } = await pool.query(
    `SELECT id, couple_id, author_id, encrypted_title, title_iv, encrypted_content, content_iv, color, is_pinned, created_at, updated_at
     FROM notes
     WHERE couple_id = $1
     ORDER BY is_pinned DESC, updated_at DESC`,
    [req.coupleId]
  );
  res.json({ notes: rows.map(toNote) });
});

const noteSchema = z.object({
  encryptedTitle: z.string().min(1),
  titleIv: z.string().min(1),
  encryptedContent: z.string().min(1),
  contentIv: z.string().min(1),
  color: z.string().optional(),
  isPinned: z.boolean().optional(),
});

router.post('/', async (req, res) => {
  const parsed = noteSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { encryptedTitle, titleIv, encryptedContent, contentIv, color, isPinned } = parsed.data;

  const { rows } = await pool.query(
    `INSERT INTO notes (couple_id, author_id, encrypted_title, title_iv, encrypted_content, content_iv, color, is_pinned)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [req.coupleId, req.userId, encryptedTitle, titleIv, encryptedContent, contentIv, color || 'rose', isPinned || false]
  );

  const note = toNote(rows[0]);
  
  broadcastToCouple(req.coupleId, {
    type: 'note:new',
    note,
  });

  res.status(201).json({ note });
});

router.patch('/:id', async (req, res) => {
  const { id } = req.params;
  const parsed = noteSchema.partial().safeParse(req.body);
  
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const updates = [];
  const params = [];
  let paramCount = 1;

  for (const [key, value] of Object.entries(parsed.data)) {
    if (value !== undefined) {
      const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
      updates.push(`${snakeKey} = $${paramCount++}`);
      params.push(value);
    }
  }

  if (updates.length === 0) {
    return res.status(400).json({ error: 'No updates provided' });
  }

  updates.push(`updated_at = now()`);
  
  params.push(id, req.coupleId);

  const { rows } = await pool.query(
    `UPDATE notes
     SET ${updates.join(', ')}
     WHERE id = $${paramCount} AND couple_id = $${paramCount + 1}
     RETURNING *`,
    params
  );

  if (rows.length === 0) {
    return res.status(404).json({ error: 'Note not found' });
  }

  const note = toNote(rows[0]);
  
  broadcastToCouple(req.coupleId, {
    type: 'note:update',
    note,
  });

  res.json({ note });
});

router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  const { rowCount } = await pool.query(
    `DELETE FROM notes WHERE id = $1 AND couple_id = $2`,
    [id, req.coupleId]
  );

  if (rowCount === 0) {
    return res.status(404).json({ error: 'Note not found' });
  }

  broadcastToCouple(req.coupleId, {
    type: 'note:delete',
    noteId: id,
  });

  res.json({ success: true });
});

export default router;
