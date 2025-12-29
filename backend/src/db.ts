import { Pool } from "pg";
import { env, requireEnv } from "./env.js";

let pool: Pool | null = null;

function getPool(): Pool {
  if (!pool) {
    const connectionString = requireEnv("DATABASE_URL", env.databaseUrl);
    pool = new Pool({ connectionString });
  }
  return pool;
}

export async function query<T = unknown>(text: string, params: unknown[] = []): Promise<T[]> {
  const result = await getPool().query(text, params);
  return result.rows as T[];
}

export async function queryOne<T = unknown>(text: string, params: unknown[] = []): Promise<T | null> {
  const rows = await query<T>(text, params);
  return rows[0] ?? null;
}
