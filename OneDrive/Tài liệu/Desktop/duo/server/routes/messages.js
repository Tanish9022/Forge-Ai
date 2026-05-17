import { Router } from 'express';
import { z } from 'zod';
import { pool } from '../db/pool.js';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { coupleMiddleware } from '../middleware/coupleMiddleware.js';
import { broadcastToCouple } from '../ws/hub.js';

const router = Router();
router.use(authMiddleware, coupleMiddleware);

function toMessage(row) {
  return {
    id: row.id,
    coupleId: row.couple_id,
    encryptedContent: row.encrypted_content,
    iv: row.iv,
    type: row.type,
    senderId: row.sender_id,
    status: row.status,
    replyTo: row.reply_to,
    reactions: row.reactions || {},
    isDeleted: row.is_deleted || false,
    createdAt: row.created_at,
  };
}

router.get('/', async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
  const before = req.query.before;

  let query = `
    SELECT id, couple_id, encrypted_content, iv, type, sender_id, status, reply_to, reactions, is_deleted, created_at
    FROM messages
    WHERE couple_id = $1`;
  const params = [req.coupleId];

  if (before) {
    query += ` AND created_at < (SELECT created_at FROM messages WHERE id = $2)`;
    params.push(before);
  }

  query += ` ORDER BY created_at DESC LIMIT $${params.length + 1}`;
  params.push(limit);

  const { rows } = await pool.query(query, params);
  res.json({ messages: rows.map(toMessage).reverse() });
});

const createSchema = z.object({
  encryptedContent: z.string().min(1),
  iv: z.string().min(1),
  type: z.enum(['text', 'image', 'voice', 'gif']).default('text'),
  senderId: z.string().uuid(),
  replyTo: z.string().uuid().nullable().optional(),
});

router.post('/', async (req, res) => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { encryptedContent, iv, type, senderId, replyTo } = parsed.data;

  if (senderId !== req.userId) {
    return res.status(403).json({ error: 'senderId must match authenticated user' });
  }

  const { rows } = await pool.query(
    `INSERT INTO messages (couple_id, encrypted_content, iv, type, sender_id, reply_to, status)
     VALUES ($1, $2, $3, $4, $5, $6, 'sent')
     RETURNING id, couple_id, encrypted_content, iv, type, sender_id, status, reply_to, reactions, is_deleted, created_at`,
    [req.coupleId, encryptedContent, iv, type, senderId, replyTo ?? null]
  );

  const message = toMessage(rows[0]);
  broadcastToCouple(req.coupleId, { type: 'message:new', message });
  res.status(201).json({ message });
});

const statusSchema = z.object({
  status: z.enum(['delivered', 'read']),
});

router.patch('/:id/status', async (req, res) => {
  const parsed = statusSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { rows } = await pool.query(
    `UPDATE messages SET status = $1
     WHERE id = $2 AND couple_id = $3
     RETURNING id, couple_id, encrypted_content, iv, type, sender_id, status, reply_to, reactions, is_deleted, created_at`,
    [parsed.data.status, req.params.id, req.coupleId]
  );

  if (rows.length === 0) {
    return res.status(404).json({ error: 'Message not found' });
  }

  const message = toMessage(rows[0]);
  broadcastToCouple(req.coupleId, {
    type: 'message:status',
    messageId: message.id,
    status: message.status,
  });
  res.json({ message });
});

const reactionSchema = z.object({
  reactions: z.record(z.string()), // e.g. { "user_id": "❤️" }
});

router.patch('/:id/reactions', async (req, res) => {
  const parsed = reactionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }

  const { rows } = await pool.query(
    `UPDATE messages SET reactions = $1
     WHERE id = $2 AND couple_id = $3
     RETURNING id, couple_id, encrypted_content, iv, type, sender_id, status, reply_to, reactions, is_deleted, created_at`,
    [parsed.data.reactions, req.params.id, req.coupleId]
  );

  if (rows.length === 0) {
    return res.status(404).json({ error: 'Message not found' });
  }

  const message = toMessage(rows[0]);
  broadcastToCouple(req.coupleId, {
    type: 'message:reactions',
    messageId: message.id,
    reactions: message.reactions,
  });
  res.json({ message });
});

router.delete('/:id', async (req, res) => {
  // Soft delete
  const { rows } = await pool.query(
    `UPDATE messages SET is_deleted = true, encrypted_content = 'deleted', iv = 'deleted'
     WHERE id = $1 AND couple_id = $2
     RETURNING id, couple_id, encrypted_content, iv, type, sender_id, status, reply_to, reactions, is_deleted, created_at`,
    [req.params.id, req.coupleId]
  );

  if (rows.length === 0) {
    return res.status(404).json({ error: 'Message not found' });
  }

  const message = toMessage(rows[0]);
  broadcastToCouple(req.coupleId, {
    type: 'message:delete',
    messageId: message.id,
  });
  res.json({ success: true, message });
});

export default router;
