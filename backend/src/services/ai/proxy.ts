import type { AppConfig } from '../../config/schema.js';
import { can, type Principal } from '../../domain/permissions.js';
import {
  internalError,
  notFound,
  unavailable,
  uncertainAiRequest,
} from '../../domain/errors.js';
import type {
  AiBilling,
  ProcessingIdentity,
  TokenUsage,
} from '../../domain/ai.js';
import type { Repository as Store } from '../../repositories/repository.js';
import { visibleProject } from '../projects.js';
import { assertQuota } from './quota.js';
import { callProvider } from './resilience.js';
import type { AiProvider } from './provider.js';
import type { Metrics } from '../metrics/metrics.js';
import { page } from '../pagination.js';
import { selectProvider, type ProviderFactory } from './provider-selection.js';
import {
  ActiveAiRequests,
  assertReceiptBinding,
  receiptBinding,
} from './receipts.js';

export interface ProxyResult {
  readonly text: string;
  readonly model: string;
  readonly provider: string;
  readonly billingKind: string;
  readonly usage: TokenUsage & {
    readonly reservedCost: number;
    readonly currency: 'configured';
  };
  readonly receipt?: {
    readonly idempotencyKey: string;
    readonly status: 'completed';
  };
}

const activeRequests = new ActiveAiRequests<ProxyResult>();
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
    billing?: AiBilling;
    processing?: ProcessingIdentity;
    maxCost?: number;
    signal?: AbortSignal;
  },
  metrics?: Metrics,
  factory?: ProviderFactory,
): Promise<ProxyResult> {
  if (!can(principal, 'aiProxy')) throw notFound();
  await visibleProject(store, principal, input.projectId);
  if (input.signal?.aborted === true) throw uncertainAiRequest();
  const selected = await selectProvider(
    store,
    config,
    provider,
    principal,
    input,
    factory,
  );
  const identity = input.processing;
  const bindingHash =
    identity === undefined
      ? undefined
      : receiptBinding(
          identity,
          principal,
          method,
          input.projectId,
          selected.model,
          selected.accountId,
          input.payload,
          input.maxCost,
        );
  // New versioned/personal/approved requests are never retried after dispatch.
  const retryLimit =
    identity !== undefined ||
    input.billing !== undefined ||
    input.maxCost !== undefined
      ? 0
      : config.aiRetryLimit;
  const policy = {
    ...config,
    aiRequestCostCeiling: selected.cost,
    aiRetryLimit: retryLimit,
  };
  const started = Date.now();
  const reservation = await store.withTransaction(async (tx) => {
    await visibleProject(tx, principal, input.projectId);
    if (identity !== undefined && bindingHash !== undefined) {
      const previous = await tx.aiReceipt(identity.idempotencyKey);
      if (previous !== undefined) {
        assertReceiptBinding(bindingHash, previous.bindingHash);
        return { replay: previous };
      }
    }
    if (selected.kind === 'personal') {
      const current = await tx.aiCredential(
        principal.userId,
        selected.providerName,
      );
      if (
        current === undefined ||
        current.revision !== selected.credentialRevision
      )
        throw unavailable();
    }
    if (input.signal?.aborted === true) throw uncertainAiRequest();
    const cost = await assertQuota(tx, policy, principal, input.projectId);
    const id = await tx.addUsage({
      projectId: input.projectId,
      userId: principal.userId,
      model: selected.model,
      provider: selected.providerName,
      billingKind: selected.kind,
      byteSize: input.payload.length,
      durationMs: 0,
      outcome: 'reserved',
      cost,
      at: new Date().toISOString(),
    });
    if (identity !== undefined && bindingHash !== undefined)
      await tx.saveAiReceipt({
        idempotencyKey: identity.idempotencyKey,
        bindingHash,
        userId: principal.userId,
        deviceId: principal.deviceId,
        projectId: input.projectId,
        usageId: id,
        status: 'running',
        createdAt: new Date().toISOString(),
      });
    return { id, cost };
  });
  if ('replay' in reservation && reservation.replay !== undefined)
    return activeRequests.read(
      store,
      reservation.replay.idempotencyKey,
      reservation.replay.bindingHash,
      reservation.replay.status,
    );
  const id = reservation.id;
  const cost = reservation.cost;
  if (id === undefined || cost === undefined) throw uncertainAiRequest();
  if (metrics !== undefined) {
    metrics.aiRequests += 1;
    metrics.aiCost += cost;
  }
  const run = async (): Promise<ProxyResult> => {
    try {
      const result = await callProvider(
        selected.provider,
        method,
        { ...input, model: selected.model, accountId: selected.accountId },
        config,
        retryLimit,
      );
      if (result.model !== selected.model) throw internalError();
      await store.withTransaction(async (tx) => {
        await tx.finishUsage(
          id,
          'ok',
          Date.now() - started,
          result.model,
          result.usage,
        );
        if (identity !== undefined) {
          const receipt = await tx.aiReceipt(identity.idempotencyKey);
          if (receipt !== undefined)
            await tx.saveAiReceipt({ ...receipt, status: 'completed' });
        }
      });
      return {
        text: result.text,
        model: result.model,
        provider: selected.providerName,
        billingKind: selected.kind,
        usage: { ...result.usage, reservedCost: cost, currency: 'configured' },
        ...(identity === undefined
          ? {}
          : {
              receipt: {
                idempotencyKey: identity.idempotencyKey,
                status: 'completed',
              },
            }),
      };
    } catch (error) {
      await store.withTransaction(async (tx) => {
        await tx.finishUsage(
          id,
          'failed',
          Date.now() - started,
          selected.model,
        );
        if (identity !== undefined) {
          const receipt = await tx.aiReceipt(identity.idempotencyKey);
          if (receipt !== undefined)
            await tx.saveAiReceipt({ ...receipt, status: 'uncertain' });
        }
      });
      throw identity === undefined ? error : uncertainAiRequest();
    }
  };
  return identity === undefined || bindingHash === undefined
    ? run()
    : activeRequests.run(store, identity.idempotencyKey, bindingHash, run);
}
export async function usageReport(
  store: Store,
  principal: Principal,
  query: {
    projectId: string;
    from: string;
    to: string;
    cursor?: string;
    limit?: number;
  },
) {
  await visibleProject(store, principal, query.projectId);
  const limit = query.limit ?? 50;
  return page(
    await store.usagePage({
      ...query,
      userId: principal.userId,
      limit: limit + 1,
    }),
    limit,
    (row) => row.id,
  );
}
