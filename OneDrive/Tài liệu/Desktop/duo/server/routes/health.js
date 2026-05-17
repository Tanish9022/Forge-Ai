import { Router } from 'express';
import { checkDbConnection } from '../db/pool.js';

const router = Router();

router.get('/', async (_req, res) => {
  let db = false;
  try {
    db = await checkDbConnection();
  } catch {
    db = false;
  }
  const ok = db;
  res.status(ok ? 200 : 503).json({ ok, db: db ? 'connected' : 'disconnected' });
});

export default router;
