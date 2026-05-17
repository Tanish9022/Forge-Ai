import http from 'http';
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

import authRoutes from './routes/auth.js';
import couplesRoutes from './routes/couples.js';
import messagesRoutes from './routes/messages.js';
import mediaRoutes from './routes/media.js';
import gamesRoutes from './routes/games.js';
import snapsRoutes from './routes/snaps.js';
import musicRoutes from './routes/music.js';
import notesRoutes from './routes/notes.js';
import statsRoutes from './routes/stats.js';
import healthRoutes from './routes/health.js';
import youtubeRoutes from './routes/youtube.js';
import { attachWebSocket } from './ws/server.js';
import { startSnapExpiryJob } from './jobs/snapExpiry.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const PORT = parseInt(process.env.PORT || '3001', 10);
const CLIENT_ORIGIN = process.env.CLIENT_ORIGIN || '*';

const app = express();
const server = http.createServer(app);

app.use(
  cors({
    origin: CLIENT_ORIGIN === '*' ? true : CLIENT_ORIGIN.split(','),
    credentials: true,
  })
);
app.use(express.json({ limit: '1mb' }));

app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/couples', couplesRoutes);
app.use('/api/messages', messagesRoutes);
app.use('/api/youtube', youtubeRoutes);
app.use('/api/media', mediaRoutes);
app.use('/api/games', gamesRoutes);
app.use('/api/snaps', snapsRoutes);
app.use('/api/music', musicRoutes);
app.use('/api/notes', notesRoutes);
app.use('/api/stats', statsRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.use((err, _req, res, _next) => {
  console.error('Unhandled error', err);
  res.status(500).json({ error: 'Internal server error' });
});

attachWebSocket(server);
startSnapExpiryJob();

server.listen(PORT, () => {
  console.log(`Atmos API listening on http://127.0.0.1:${PORT}`);
  console.log(`WebSocket: ws://127.0.0.1:${PORT}/ws?token=<jwt>`);
});
