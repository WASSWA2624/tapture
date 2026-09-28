import type { Principal } from '../../domain/permissions.js';
import { quotaExceeded } from '../../domain/errors.js';
import type { Repository as Store } from '../../repositories/repository.js';
const projectCeiling = 100;
/// Refuses the call before the provider when the project is over its ceiling.
export async function assertQuota(
  store: Store,
  principal: Principal,
  projectId: string,
): Promise<void> {
  const used = (await store.usage()).filter(
    (row) => row.projectId === projectId && row.userId === principal.userId,
  ).length;
  if (used >= projectCeiling) throw quotaExceeded();
}
