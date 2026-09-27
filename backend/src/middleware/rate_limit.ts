import type { NextFunction, Request, Response } from 'express';
import { rateLimited } from '../domain/errors.js';
import type { Deps } from '../deps.js';

interface Bucket {
  hits: number[];
}

const buckets = new Map<string, Bucket>();

export function rateLimit(deps: Deps, kind: 'auth' | 'general') {
  const limit =
    kind === 'auth' ? deps.config.rateLimitAuth : deps.config.rateLimitGeneral;
  return (req: Request, _res: Response, next: NextFunction): void => {
    const key = `${kind}:${req.ip ?? 'unknown'}`;
    const now = Date.now();
    const bucket = buckets.get(key) ?? { hits: [] };
    bucket.hits = bucket.hits.filter((hit) => now - hit < 60_000);
    if (bucket.hits.length >= limit) {
      deps.store.recordSecurity({
        actorId: 'rate-limit',
        action: 'rate_limited',
        target: key,
        before: null,
        after: { limit },
      });
      next(rateLimited());
      return;
    }
    bucket.hits.push(now);
    buckets.set(key, bucket);
    next();
  };
}

export function resetRateLimits(): void {
  buckets.clear();
}
