import { pool } from '../db/pool.js';
import fs from 'fs';
import path from 'path';

const storagePath = path.join(process.cwd(), 'server', 'storage', 'media');

export async function processSnapExpiry() {
  try {
    // Find snaps that have expired
    const { rows } = await pool.query(
      `DELETE FROM snaps 
       WHERE expires_at IS NOT NULL AND expires_at <= now()
       RETURNING storage_ref`
    );
    
    for (const row of rows) {
      // row.storage_ref is like /media/filename.ext
      const filename = row.storage_ref.split('/').pop();
      if (filename) {
        const filePath = path.join(storagePath, filename);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
          console.log(`Deleted expired snap file: ${filename}`);
        }
      }
    }
  } catch (err) {
    console.error('Error processing snap expiry', err);
  }
}

let intervalId;

export function startSnapExpiryJob() {
  // Run every 5 seconds
  intervalId = setInterval(processSnapExpiry, 5000);
}

export function stopSnapExpiryJob() {
  if (intervalId) {
    clearInterval(intervalId);
  }
}
