import type { Store } from '../repositories/store.js';
import type { AuditEvent } from '../types/index.js';

export function recordAudit(
  store: Store,
  event: Omit<AuditEvent, 'id' | 'at'>,
): void {
  store.recordAudit(event);
}

export function listAudit(store: Store): AuditEvent[] {
  return store.audit();
}
