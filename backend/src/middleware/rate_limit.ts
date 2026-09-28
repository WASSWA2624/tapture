import type { NextFunction, Request, Response } from 'express';
import { rateLimited } from '../domain/errors.js';
import type { Deps } from '../deps.js';
interface Bucket {
  hits: number[];
}
const buckets = new Map<string, Bucket>();

/// Records a rejection. Never rejects: a failed audit write must not stall or
/// crash the 429 answer, because Express 4 ignores a middleware's promise.
async function auditRejection(
  deps: Deps,
  target: string,
  limit: number,
): Promise<void> {
  try {
    await deps.store.recordSecurity({
      actorId: 'rate-limit',
      action: 'rate_limited',
      target,
      before: null,
      after: { limit },
    });
  } catch (error) {
    deps.log.warn('rate_limit_audit_failed', {
      outcome: 'failed',
      name: error instanceof Error ? error.name : 'unknown',
    });
  }
}

export function rateLimit(deps: Deps, kind: 'auth' | 'general') {
  const limit =
    kind === 'auth' ? deps.config.rateLimitAuth : deps.config.rateLimitGeneral;
  return async (
    req: Request,
    _res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const key = `${kind}:${req.ip ?? 'unknown'}`;
    const now = Date.now();
    const bucket = buckets.get(key) ?? { hits: [] };
    bucket.hits = bucket.hits.filter((hit) => now - hit < 60000);
    if (bucket.hits.length >= limit) {
      await auditRejection(deps, key, limit);
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
