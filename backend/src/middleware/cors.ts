import type { NextFunction, Request, Response } from 'express';
import type { AppConfig } from '../config/schema.js';
import { forbidden } from '../domain/errors.js';

const allowMethods = 'GET, POST, PUT, PATCH, DELETE';
const allowHeaders =
  'Authorization, Content-Type, X-Api-Version, Idempotency-Key';
const exposeHeaders = 'Retry-After, X-Request-Id';
const maxAgeSeconds = '600';

/// Allow-listed CORS for the web client. Mount it before authentication and
/// rate limiting so preflights never need a token. An empty list sends no CORS
/// headers. Credentials are never allowed: the client sends bearer tokens only.
export function cors(config: Pick<AppConfig, 'corsOrigins'>) {
  const allowed = new Set(config.corsOrigins);
  return (req: Request, res: Response, next: NextFunction): void => {
    if (allowed.size === 0) {
      next();
      return;
    }
    res.vary('Origin');
    const origin = req.header('origin');
    const permitted =
      origin !== undefined && allowed.has(origin) ? origin : undefined;
    if (permitted !== undefined) {
      res.setHeader('access-control-allow-origin', permitted);
      res.setHeader('access-control-expose-headers', exposeHeaders);
    }
    const preflight =
      req.method === 'OPTIONS' &&
      origin !== undefined &&
      req.header('access-control-request-method') !== undefined;
    if (!preflight) {
      next();
      return;
    }
    if (permitted === undefined) {
      next(forbidden());
      return;
    }
    res.setHeader('access-control-allow-methods', allowMethods);
    res.setHeader('access-control-allow-headers', allowHeaders);
    res.setHeader('access-control-max-age', maxAgeSeconds);
    res.status(204).end();
  };
}
