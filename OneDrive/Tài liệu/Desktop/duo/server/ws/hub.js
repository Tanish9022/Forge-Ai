/** @type {Map<string, Set<import('ws').WebSocket>>} */
const coupleRooms = new Map();

/** @type {Map<import('ws').WebSocket, { userId: string, coupleId: string | null }>} */
const socketMeta = new Map();

export function registerSocket(ws, userId, coupleId) {
  socketMeta.set(ws, { userId, coupleId });
  if (coupleId) {
    joinCoupleRoom(ws, coupleId);
  }
}

export function joinCoupleRoom(ws, coupleId) {
  const meta = socketMeta.get(ws);
  if (meta) meta.coupleId = coupleId;

  if (!coupleRooms.has(coupleId)) {
    coupleRooms.set(coupleId, new Set());
  }
  coupleRooms.get(coupleId).add(ws);
}

export function unregisterSocket(ws) {
  const meta = socketMeta.get(ws);
  if (meta?.coupleId) {
    coupleRooms.get(meta.coupleId)?.delete(ws);
  }
  socketMeta.delete(ws);
}

export function broadcastToCouple(coupleId, payload) {
  const room = coupleRooms.get(coupleId);
  if (!room) return;
  const data = JSON.stringify(payload);
  for (const client of room) {
    if (client.readyState === 1) {
      client.send(data);
    }
  }
}

export function broadcastToUser(userId, payload) {
  const data = JSON.stringify(payload);
  for (const [ws, meta] of socketMeta) {
    if (meta.userId === userId && ws.readyState === 1) {
      ws.send(data);
    }
  }
}
