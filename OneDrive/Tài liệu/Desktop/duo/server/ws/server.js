import { WebSocketServer } from 'ws';
import { verifyToken } from '../utils/tokens.js';
import { pool } from '../db/pool.js';
import {
  registerSocket,
  unregisterSocket,
  joinCoupleRoom,
  broadcastToCouple,
} from './hub.js';

export function attachWebSocket(server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', async (ws, req) => {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const token = url.searchParams.get('token');

    if (!token) {
      ws.close(4001, 'Missing token');
      return;
    }

    let userId;
    try {
      const payload = verifyToken(token);
      userId = payload.userId;
    } catch {
      ws.close(4001, 'Invalid token');
      return;
    }

    const { rows } = await pool.query(
      'SELECT couple_id FROM users WHERE id = $1',
      [userId]
    );
    const coupleId = rows[0]?.couple_id ?? null;
    registerSocket(ws, userId, coupleId);

    ws.send(JSON.stringify({ type: 'connected', userId, coupleId }));

    ws.on('message', (raw) => {
      let data;
      try {
        data = JSON.parse(raw.toString());
      } catch {
        return;
      }

      switch (data.type) {
        case 'typing:start':
        case 'typing:stop':
          if (coupleId) {
            broadcastToCouple(coupleId, {
              type: data.type,
              userId,
            });
          }
          break;
        case 'couple:join':
          if (data.coupleId) {
            joinCoupleRoom(ws, data.coupleId);
          }
          break;
        default:
          break;
      }
    });

    ws.on('close', () => unregisterSocket(ws));
    ws.on('error', () => unregisterSocket(ws));
  });

  return wss;
}
