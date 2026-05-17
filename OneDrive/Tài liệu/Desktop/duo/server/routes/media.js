import { Router } from 'express';
import multer from 'multer';
import crypto from 'crypto';
import path from 'path';
import fs from 'fs';
import { authMiddleware } from '../middleware/authMiddleware.js';
import { coupleMiddleware } from '../middleware/coupleMiddleware.js';

const router = Router();
router.use(authMiddleware, coupleMiddleware);

const storagePath = path.join(process.cwd(), 'server', 'storage', 'media');
if (!fs.existsSync(storagePath)) {
  fs.mkdirSync(storagePath, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, storagePath);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.bin';
    const uniqueName = crypto.randomUUID() + ext;
    cb(null, uniqueName);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB limit
});

router.post('/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  // The client will store the path/filename in the encrypted message
  const fileUrl = `/api/media/${req.file.filename}`;
  res.status(201).json({ url: fileUrl });
});

router.get('/:filename', (req, res) => {
  // Authorization is handled by authMiddleware and coupleMiddleware.
  // We assume any linked user can fetch media for their couple.
  // In a stricter setup, we might prefix the file with couple_id.
  const filePath = path.join(storagePath, req.params.filename);
  
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }

  res.sendFile(filePath);
});

export default router;
