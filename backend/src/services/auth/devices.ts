import { notFound } from '../../domain/errors.js';
import type { Principal } from '../../domain/permissions.js';
import { withTransaction } from '../../repositories/base.js';
import type { Repository as Store } from '../../repositories/repository.js';
import type { Device } from '../../types/index.js';
export async function listDevices(
  store: Store,
  principal: Principal,
): Promise<Device[]> {
  return (await store.devices()).filter(
    (row) => row.userId === principal.userId,
  );
}
export async function revokeDevice(
  store: Store,
  principal: Principal,
  deviceId: string,
): Promise<void> {
  const device = (await store.devices()).find(
    (row) => row.id === deviceId && row.userId === principal.userId,
  );
  if (device === undefined) throw notFound();
  await withTransaction(store, async (tx) => {
    await tx.saveDevice({ ...device, revoked: true });
    for (const family of await tx.refresh()) {
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
