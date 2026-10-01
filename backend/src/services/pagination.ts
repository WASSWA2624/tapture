import { invalidRequest } from '../domain/errors.js';
import type { PackagePosition } from '../repositories/queries.js';

export interface Page<T> {
  readonly items: T[];
  readonly nextCursor: string | null;
}

/// Repositories fetch one extra row so no separate count query is needed.
export function page<T>(
  rows: T[],
  limit: number,
  cursor: (row: T) => string,
): Page<T> {
  const items = rows.slice(0, limit);
  const last = items.at(-1);
  return {
    items,
    nextCursor: rows.length > limit && last !== undefined ? cursor(last) : null,
  };
}

export function packageCursor(position: PackagePosition): string {
  return Buffer.from(
    JSON.stringify([position.createdAt, position.id]),
  ).toString('base64url');
}

/// Carry the ordering position in the cursor; acknowledgement or purge may
/// remove the previous row before the device asks for its next page.
export function readPackageCursor(cursor: string): PackagePosition {
  let value: unknown;
  try {
    value = JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8'));
  } catch {
    throw invalidRequest('Invalid cursor.');
  }
  if (
    !Array.isArray(value) ||
    value.length !== 2 ||
    typeof value[0] !== 'string' ||
    !Number.isFinite(Date.parse(value[0])) ||
    new Date(value[0]).toISOString() !== value[0] ||
    typeof value[1] !== 'string' ||
    value[1].length === 0
  )
    throw invalidRequest('Invalid cursor.');
  const position = { createdAt: value[0], id: value[1] };
  if (packageCursor(position) !== cursor)
    throw invalidRequest('Invalid cursor.');
  return position;
}
