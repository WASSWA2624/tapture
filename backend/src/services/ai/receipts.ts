import { createHash } from 'node:crypto';
import type { ProcessingIdentity } from '../../domain/ai.js';
import {
  conflict,
  invalidRequest,
  uncertainAiRequest,
  unavailableAiResult,
} from '../../domain/errors.js';
import type { Principal } from '../../domain/permissions.js';
import type { Repository } from '../../repositories/repository.js';

export function receiptBinding(
  identity: ProcessingIdentity,
  principal: Principal,
  method: string,
  projectId: string,
  model: string,
  accountId: string,
  payload: Buffer,
  maxCost?: number,
): string {
  const hash = createHash('sha256').update(payload).digest('hex');
  if (hash !== identity.requestHash)
    throw invalidRequest(
      'The processing content hash does not match this request.',
    );
  return createHash('sha256')
    .update(
      JSON.stringify([
        identity.version,
        identity.projectRevision,
        identity.recordId,
        hash,
        principal.organisationId,
        principal.userId,
        principal.deviceId,
        projectId,
        method,
        model,
        accountId,
        maxCost ?? null,
      ]),
    )
    .digest('hex');
}

interface ActiveRequest<T> {
  readonly bindingHash: string;
  readonly result: Promise<T>;
}

/** Only coalesce requests while the original HTTP operation is still in flight. */
export class ActiveAiRequests<T> {
  private readonly active = new WeakMap<
    Repository,
    Map<string, ActiveRequest<T>>
  >();

  read(
    store: Repository,
    key: string,
    bindingHash: string,
    status: string,
  ): Promise<T> {
    const cached = this.active.get(store)?.get(key);
    if (cached !== undefined && cached.bindingHash === bindingHash)
      return cached.result;
    throw status === 'completed' ? unavailableAiResult() : uncertainAiRequest();
  }

  async run(
    store: Repository,
    key: string,
    bindingHash: string,
    work: () => Promise<T>,
  ): Promise<T> {
    const cache = this.active.get(store) ?? new Map<string, ActiveRequest<T>>();
    this.active.set(store, cache);
    const result = work();
    cache.set(key, { bindingHash, result });
    try {
      return await result;
    } finally {
      cache.delete(key);
    }
  }
}

export function assertReceiptBinding(expected: string, actual: string): void {
  if (expected !== actual)
    throw conflict(
      'This processing attempt identifier was already used for different content or billing.',
    );
}
