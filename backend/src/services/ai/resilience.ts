import type { AppConfig } from '../../config/schema.js';
import { AppError, internalError, rateLimited } from '../../domain/errors.js';
import type { AiProvider, AiRequest, AiResult } from './provider.js';

interface Breaker {
  failures: number;
  openUntil: number;
}

const breakers = new Map<string, Breaker>();

async function timedCall(
  provider: AiProvider,
  method: keyof AiProvider,
  request: AiRequest,
  timeoutMs: number,
): Promise<AiResult> {
  const controller = new AbortController();
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
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
          reject(new Error('timeout'));
        }, timeoutMs);
      }),
    ]);
  } finally {
    // Successful calls release their deadline immediately. A busy proxy must
    // not keep one timer per completed request until the timeout elapses.
    clearTimeout(timer);
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
): Promise<AiResult> {
  const breaker = breakers.get(request.model) ?? { failures: 0, openUntil: 0 };
  if (breaker.openUntil > Date.now()) throw rateLimited();
  let last: unknown;
  for (let attempt = 0; attempt <= config.aiRetryLimit; attempt += 1) {
    try {
      const result = await timedCall(
        provider,
        method,
        request,
        config.aiTimeoutMs,
      );
      breakers.set(request.model, { failures: 0, openUntil: 0 });
      if (result.text.length === 0) throw new Error('malformed');
      return result;
    } catch (error) {
      if (isFinal(error)) throw error;
      last = error;
      breaker.failures += 1;
      if (breaker.failures >= config.aiBreakerThreshold) {
        breaker.openUntil = Date.now() + config.aiTimeoutMs;
      }
      breakers.set(request.model, breaker);
      await sleep(20 * (attempt + 1));
    }
  }
  if (last instanceof Error && last.message === 'malformed') {
    throw internalError();
  }
  throw rateLimited();
}

export function resetBreakers(): void {
  breakers.clear();
}
