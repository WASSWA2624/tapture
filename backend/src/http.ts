import type { NextFunction, Request, Response } from 'express';
import { invalidRequest } from './domain/errors.js';

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
  return typeof value === 'string' && value.length > 0 ? value : undefined;
}
