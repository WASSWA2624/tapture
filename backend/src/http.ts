import type { NextFunction, Request, Response } from 'express';
import { invalidRequest } from './domain/errors.js';

export function objectBody(
  body: unknown,
  allowedFields?: readonly string[],
): Record<string, unknown> {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    throw invalidRequest('Expected a JSON object.');
  }
  if (
    allowedFields !== undefined &&
    Object.keys(body).some((key) => !allowedFields.includes(key))
  )
    throw invalidRequest('Unknown request field.');
  return body as Record<string, unknown>;
}

export function pageQuery(query: Record<string, unknown>): {
  cursor?: string;
  limit: number;
} {
  const cursor = query['cursor'];
  const value = query['limit'];
  if (
    cursor !== undefined &&
    (typeof cursor !== 'string' || cursor.length === 0)
  )
    throw invalidRequest('Invalid cursor.');
  if (
    value !== undefined &&
    (typeof value !== 'string' || !/^[1-9][0-9]*$/.test(value))
  )
    throw invalidRequest('Limit must be a whole number from 1 to 100.');
  const limit = value === undefined ? 50 : Number(value);
  if (!Number.isSafeInteger(limit) || limit > 100)
    throw invalidRequest('Limit must be a whole number from 1 to 100.');
  return { ...(typeof cursor === 'string' ? { cursor } : {}), limit };
}

export function asyncRoute(
  work: (req: Request, res: Response) => Promise<void>,
): (req: Request, res: Response, next: NextFunction) => void {
  return (req, res, next) => {
    void work(req, res).catch(next);
  };
}

export function field(body: unknown, name: string): string {
  if (body === null || typeof body !== 'object' || !(name in body)) {
    throw invalidRequest(`Missing ${name}.`);
  }
  const value = (body as Record<string, unknown>)[name];
  if (typeof value !== 'string' || value.length === 0) {
    throw invalidRequest(`Missing ${name}.`);
  }
  return value;
}

export function optionalField(body: unknown, name: string): string | undefined {
  if (body === null || typeof body !== 'object' || !(name in body))
    return undefined;
  const value = (body as Record<string, unknown>)[name];
  if (typeof value !== 'string' || value.length === 0)
    throw invalidRequest(`Invalid ${name}.`);
  return value;
}
