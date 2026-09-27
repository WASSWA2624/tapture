import type { Principal } from '../../domain/permissions.js';
import { quotaExceeded } from '../../domain/errors.js';
import type { Store } from '../../repositories/store.js';

const projectCeiling = 100;

/// Refuses the call before the provider when the project is over its ceiling.
export function assertQuota(
  store: Store,
  principal: Principal,
  projectId: string,
): void {
  const used = store
    .usage()
    .filter(
      (row) => row.projectId === projectId && row.userId === principal.userId,
    ).length;
  if (used >= projectCeiling) throw quotaExceeded();
}
