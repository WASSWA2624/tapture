import type { AppConfig } from '../../config/schema.js';
import { internalError, rateLimited } from '../../domain/errors.js';
import type { AiProvider, AiRequest, AiResult } from './provider.js';

interface Breaker {
  failures: number;
  openUntil: number;
}

const breakers = new Map<string, Breaker>();

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
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
      const result = await Promise.race([
        provider[method](request),
        sleep(config.aiTimeoutMs).then(() => {
          throw new Error('timeout');
        }),
      ]);
      breakers.set(request.model, { failures: 0, openUntil: 0 });
      if (result.text.length === 0) throw new Error('malformed');
      return result;
    } catch (error) {
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
