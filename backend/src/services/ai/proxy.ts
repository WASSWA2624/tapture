import type { AppConfig } from '../../config/schema.js';
import { can, type Principal } from '../../domain/permissions.js';
import { invalidRequest, notFound } from '../../domain/errors.js';
import type { Repository as Store } from '../../repositories/repository.js';
import { visibleProject } from '../projects.js';
import { assertQuota } from './quota.js';
import { callProvider } from './resilience.js';
import type { AiProvider } from './provider.js';
import type { Metrics } from '../metrics/metrics.js';
export async function proxyAi(
  store: Store,
  config: AppConfig,
  provider: AiProvider,
  principal: Principal,
  method: 'extract' | 'ocr' | 'transcribe' | 'refine',
  input: {
    projectId: string;
    model: string;
    payload: Buffer;
  },
  metrics?: Metrics,
): Promise<{
  text: string;
  model: string;
}> {
  if (!can(principal, 'aiProxy')) throw notFound();
  if (input.model !== 'default' && input.model !== config.aiProviderModel)
    throw invalidRequest(
      'This analysis model is not enabled by your organisation.',
    );
  const started = Date.now();
  const reservation = await store.withTransaction(async (tx) => {
    await visibleProject(tx, principal, input.projectId);
    const cost = await assertQuota(tx, config, principal, input.projectId);
    const id = await tx.addUsage({
      projectId: input.projectId,
      userId: principal.userId,
      model: input.model,
      byteSize: input.payload.length,
      durationMs: 0,
      outcome: 'reserved',
      cost,
      at: new Date().toISOString(),
    });
    return { id, cost };
  });
  if (metrics !== undefined) {
    metrics.aiRequests += 1;
    metrics.aiCost += reservation.cost;
  }
  try {
    const result = await callProvider(provider, method, input, config);
    await store.finishUsage(
      reservation.id,
      'ok',
      Date.now() - started,
      result.model,
    );
    return { text: result.text, model: result.model };
  } catch (error) {
    await store.finishUsage(
      reservation.id,
      'failed',
      Date.now() - started,
      input.model,
    );
    throw error;
  }
}
export async function usageReport(
  store: Store,
  principal: Principal,
  query: {
    projectId: string;
    from: string;
    to: string;
  },
) {
  await visibleProject(store, principal, query.projectId);
  return (await store.usage()).filter((row) => {
    return (
      row.projectId === query.projectId &&
      row.at >= query.from &&
      row.at <= query.to &&
      row.userId === principal.userId
    );
  });
}
