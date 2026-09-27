import type { AppConfig } from '../../config/schema.js';
import { can, type Principal } from '../../domain/permissions.js';
import { notFound } from '../../domain/errors.js';
import type { Store } from '../../repositories/store.js';
import { visibleProject } from '../projects.js';
import { assertQuota } from './quota.js';
import { callProvider } from './resilience.js';
import type { AiProvider } from './provider.js';

export async function proxyAi(
  store: Store,
  config: AppConfig,
  provider: AiProvider,
  principal: Principal,
  method: 'extract' | 'ocr' | 'transcribe' | 'refine',
  input: { projectId: string; model: string; payload: Buffer },
): Promise<{ text: string; model: string }> {
  if (!can(principal, 'aiProxy')) throw notFound();
  visibleProject(store, principal, input.projectId);
  assertQuota(store, principal, input.projectId);
  const started = Date.now();
  try {
    const result = await callProvider(provider, method, input, config);
    store.addUsage({
      projectId: input.projectId,
      userId: principal.userId,
      model: result.model,
      byteSize: input.payload.length,
      durationMs: Date.now() - started,
      outcome: 'ok',
      cost: input.payload.length / 1000,
      at: new Date().toISOString(),
    });
    return { text: result.text, model: result.model };
  } catch (error) {
    store.addUsage({
      projectId: input.projectId,
      userId: principal.userId,
      model: input.model,
      byteSize: input.payload.length,
      durationMs: Date.now() - started,
      outcome: 'failed',
      cost: 0,
      at: new Date().toISOString(),
    });
    throw error;
  }
}

export function usageReport(
  store: Store,
  principal: Principal,
  query: { projectId: string; from: string; to: string },
) {
  visibleProject(store, principal, query.projectId);
  return store.usage().filter((row) => {
    return (
      row.projectId === query.projectId &&
      row.at >= query.from &&
      row.at <= query.to &&
      row.userId === principal.userId
    );
  });
}
