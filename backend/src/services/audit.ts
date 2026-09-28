import type { Repository as Store } from '../repositories/repository.js';
import type { AuditEvent } from '../types/index.js';
export async function recordAudit(
  store: Store,
  event: Omit<AuditEvent, 'id' | 'at'>,
): Promise<void> {
  await store.recordAudit(event);
}
export async function listAudit(store: Store): Promise<AuditEvent[]> {
  return await store.audit();
}
