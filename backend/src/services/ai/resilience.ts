import type { AppConfig } from '../../config/schema.js';
import {
  AppError,
  internalError,
  rateLimited,
  uncertainAiRequest,
} from '../../domain/errors.js';
import type { AiProvider, AiRequest, AiResult } from './provider.js';

interface Breaker {
  failures: number;
  openUntil: number;
}

let breakers = new WeakMap<AppConfig, Map<string, Breaker>>();

async function timedCall(
  provider: AiProvider,
  method: keyof AiProvider,
  request: AiRequest,
  timeoutMs: number,
): Promise<AiResult> {
  const controller = new AbortController();
  let timer: ReturnType<typeof setTimeout> | undefined;
  let detach: () => void = () => undefined;
  try {
    if (request.signal?.aborted === true) throw uncertainAiRequest();
    return await Promise.race([
      provider[method]({
        ...request,
        signal:
          request.signal === undefined
            ? controller.signal
            : AbortSignal.any([request.signal, controller.signal]),
      }),
      new Promise<never>((_resolve, reject) => {
        timer = setTimeout(() => {
          controller.abort();
          reject(uncertainAiRequest());
        }, timeoutMs);
        const abort = () => reject(uncertainAiRequest());
        request.signal?.addEventListener('abort', abort, { once: true });
        detach = () => request.signal?.removeEventListener('abort', abort);
      }),
    ]);
  } finally {
    // Successful calls release their deadline immediately. A busy proxy must
    // not keep one timer per completed request until the timeout elapses.
    clearTimeout(timer);
    detach();
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

/// A client fault or missing configuration. A retry cannot change the answer,
/// and it says nothing about the provider's health, so it never trips the
/// breaker and reaches the caller unchanged.
function isFinal(error: unknown): boolean {
  if (!(error instanceof AppError)) return false;
  if (error.code === 'unavailable') return true;
  return error.status < 500 && error.status !== 429;
}

/// Timeout, bounded retry, and a circuit breaker around one provider call.
export async function callProvider(
  provider: AiProvider,
  method: keyof AiProvider,
  request: AiRequest,
  config: AppConfig,
  retryLimit = config.aiRetryLimit,
): Promise<AiResult> {
  const pool = breakers.get(config) ?? new Map<string, Breaker>();
  breakers.set(config, pool);
  const key = `${request.accountId ?? 'legacy'}:${request.model}`;
  const breaker = pool.get(key) ?? { failures: 0, openUntil: 0 };
  if (breaker.openUntil > Date.now()) throw rateLimited();
  let last: unknown;
  for (let attempt = 0; attempt <= retryLimit; attempt += 1) {
    try {
      const result = await timedCall(
        provider,
        method,
        request,
        config.aiTimeoutMs,
      );
      pool.set(key, { failures: 0, openUntil: 0 });
      if (result.text.length === 0) throw new Error('malformed');
      return result;
    } catch (error) {
      if (
        request.signal?.aborted === true ||
        (error instanceof Error &&
          ['AbortError', 'TimeoutError'].includes(error.name))
      )
        throw uncertainAiRequest();
      if (isFinal(error)) throw error;
      last = error;
      breaker.failures += 1;
      if (breaker.failures >= config.aiBreakerThreshold) {
        breaker.openUntil = Date.now() + config.aiTimeoutMs;
      }
      pool.set(key, breaker);
      if (attempt < retryLimit) await sleep(20 * (attempt + 1));
    }
  }
  if (last instanceof Error && last.message === 'malformed') {
    throw internalError();
  }
  throw rateLimited();
}

export function resetBreakers(): void {
  breakers = new WeakMap();
}
