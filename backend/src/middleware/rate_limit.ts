import type { NextFunction, Request, Response } from 'express';
import { rateLimited } from '../domain/errors.js';
import type { Deps } from '../deps.js';
interface Bucket {
  hits: number[];
}
interface LimiterState {
  readonly buckets: Map<string, Bucket>;
  nextPruneAt: number;
}
const WINDOW_MS = 60_000;
let limiterStates = new WeakMap<Deps, Map<'auth' | 'general', LimiterState>>();

function stateFor(deps: Deps, kind: 'auth' | 'general'): LimiterState {
  let states = limiterStates.get(deps);
  if (states === undefined) {
    states = new Map();
    limiterStates.set(deps, states);
  }
  let state = states.get(kind);
  if (state === undefined) {
    state = { buckets: new Map(), nextPruneAt: 0 };
    states.set(kind, state);
  }
  return state;
}

function prune(state: LimiterState, now: number): void {
  if (now < state.nextPruneAt) return;
  let nextPruneAt = now + WINDOW_MS;
  for (const [address, bucket] of state.buckets) {
    const last = bucket.hits.at(-1);
    if (last === undefined || now - last >= WINDOW_MS)
      state.buckets.delete(address);
    else nextPruneAt = Math.min(nextPruneAt, last + WINDOW_MS);
  }
  state.nextPruneAt = nextPruneAt;
}

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
    const state = stateFor(deps, kind);
    prune(state, now);
    const existing = state.buckets.get(key);
    // Refuse additional addresses while the bounded window is full. This
    // avoids an IP churn attack evicting active buckets to bypass their limits.
    if (
      existing === undefined &&
      state.buckets.size >= deps.config.rateLimitBucketLimit
    ) {
      await auditRejection(deps, key, deps.config.rateLimitBucketLimit);
      next(rateLimited());
      return;
    }
    const bucket = existing ?? { hits: [] };
    bucket.hits = bucket.hits.filter((hit) => now - hit < WINDOW_MS);
    if (bucket.hits.length >= limit) {
      await auditRejection(deps, key, limit);
      next(rateLimited());
      return;
    }
    bucket.hits.push(now);
    state.buckets.set(key, bucket);
    next();
  };
}
export function resetRateLimits(): void {
  limiterStates = new WeakMap();
}
