import { notFound } from '../../domain/errors.js';
import type { Principal } from '../../domain/permissions.js';
import { withTransaction } from '../../repositories/base.js';
import type { Repository as Store } from '../../repositories/repository.js';
import type { Device } from '../../types/index.js';
import type { PageQuery } from '../../repositories/queries.js';
import { page, type Page } from '../pagination.js';
export async function listDevices(
  store: Store,
  principal: Principal,
  query: PageQuery = {},
): Promise<Page<Device>> {
  const limit = query.limit ?? 50;
  return page(
    await store.devices({
      ...query,
      userId: principal.userId,
      limit: limit + 1,
    }),
    limit,
    (row) => row.id,
  );
}
export async function revokeDevice(
  store: Store,
  principal: Principal,
  deviceId: string,
): Promise<void> {
  const device = await store.deviceById(deviceId);
  if (device === undefined || device.userId !== principal.userId)
    throw notFound();
  await withTransaction(store, async (tx) => {
    await tx.saveDevice({ ...device, revoked: true });
    for (const family of await tx.refreshForUser(principal.userId)) {
      if (family.deviceId === deviceId)
        await tx.saveRefresh({ ...family, revoked: true });
    }
    await tx.recordAudit({
      actorId: principal.userId,
      action: 'revoke_device',
      target: deviceId,
      before: { revoked: false },
      after: { revoked: true },
    });
  });
}
