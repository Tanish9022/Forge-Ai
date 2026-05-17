import { Router } from 'express';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = Router();
router.use(authMiddleware);

router.get('/search', async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (!q) {
    return res.status(400).json({ error: 'Query parameter q is required' });
  }

  const apiKey = process.env.YOUTUBE_API_KEY;
  if (!apiKey) {
    return res.status(503).json({ error: 'YouTube search unavailable' });
  }

  const params = new URLSearchParams({
    part: 'snippet',
    type: 'video',
    maxResults: '10',
    q,
    key: apiKey,
  });

  try {
    const response = await fetch(
      `https://www.googleapis.com/youtube/v3/search?${params}`
    );
    const data = await response.json();

    if (!response.ok) {
      console.error('YouTube API error', data);
      return res.status(response.status).json({
        error: data.error?.message || 'YouTube search failed',
      });
    }

    const items = (data.items || []).map((item) => ({
      videoId: item.id?.videoId,
      title: item.snippet?.title,
      channelTitle: item.snippet?.channelTitle,
      thumbnailUrl: item.snippet?.thumbnails?.medium?.url,
    }));

    res.json({ items });
  } catch (err) {
    console.error('youtube proxy error', err);
    res.status(502).json({ error: 'Failed to reach YouTube API' });
  }
});

export default router;
