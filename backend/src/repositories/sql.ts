import type { SqlConnection } from '../db/pool.js';
import { conflict, invalidRequest } from '../domain/errors.js';

/// Parameterised statements over one pool or transaction connection.
export class Sql {
  constructor(readonly connection: SqlConnection) {}

  async rows<T>(text: string, values: unknown[] = []): Promise<T[]> {
    try {
      const rows = await this.connection.query(text, values);
      // Columns are selected and aliased by the repository and constrained by
      // migrations. Convert only the driver's Date/numeric representations.
      return rows.map(
        (row) =>
          Object.fromEntries(
            Object.entries(row).map(([key, value]) => [
              key,
              value instanceof Date
                ? value.toISOString()
                : key === 'cost' && typeof value === 'string'
                  ? Number(value)
                  : value,
            ]),
          ) as T,
      );
    } catch (error) {
      const code =
        typeof error === 'object' && error !== null && 'code' in error
          ? error.code
          : null;
      if (code === '23505') throw conflict('That entry already exists.');
      if (code === '23503' || code === '23514')
        throw invalidRequest('The related entry is missing or invalid.');
      throw error;
    }
  }

  async write(text: string, values: unknown[] = []): Promise<void> {
    await this.rows(text, values);
  }
}
