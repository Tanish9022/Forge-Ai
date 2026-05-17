import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from './pool.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationsDir = path.join(__dirname, 'migrations');

async function ensureMigrationsTable(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id         SERIAL PRIMARY KEY,
      name       TEXT UNIQUE NOT NULL,
      applied_at TIMESTAMPTZ DEFAULT now()
    )
  `);
}

async function getAppliedMigrations(client) {
  const { rows } = await client.query(
    'SELECT name FROM schema_migrations ORDER BY id'
  );
  return new Set(rows.map((r) => r.name));
}

async function runMigration(client, filename) {
  const sqlPath = path.join(migrationsDir, filename);
  const sql = fs.readFileSync(sqlPath, 'utf8');
  await client.query('BEGIN');
  try {
    await client.query(sql);
    await client.query(
      'INSERT INTO schema_migrations (name) VALUES ($1) ON CONFLICT (name) DO NOTHING',
      [filename]
    );
    await client.query('COMMIT');
    console.log(`Applied: ${filename}`);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  }
}

async function migrate() {
  const client = await pool.connect();
  try {
    await ensureMigrationsTable(client);
    const applied = await getAppliedMigrations(client);
    const files = fs
      .readdirSync(migrationsDir)
      .filter((f) => f.endsWith('.sql'))
      .sort();

    for (const file of files) {
      if (applied.has(file)) {
        console.log(`Skipped (already applied): ${file}`);
        continue;
      }
      await runMigration(client, file);
    }
    console.log('Migrations complete.');
  } finally {
    client.release();
    await pool.end();
  }
}

migrate().catch((err) => {
  console.error('Migration failed:', err.message);
  process.exit(1);
});
