import type { AppConfig } from '../../config/schema.js';
import { can, type Principal } from '../../domain/permissions.js';
import { notFound } from '../../domain/errors.js';
import type { Repository as Store } from '../../repositories/repository.js';
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
  input: {
    projectId: string;
    model: string;
    payload: Buffer;
  },
): Promise<{
  text: string;
  model: string;
}> {
  if (!can(principal, 'aiProxy')) throw notFound();
  await visibleProject(store, principal, input.projectId);
  await assertQuota(store, principal, input.projectId);
  const started = Date.now();
  try {
    const result = await callProvider(provider, method, input, config);
    await store.addUsage({
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
    await store.addUsage({
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
