import { notFound } from '../../domain/errors.js';
import type { Principal } from '../../domain/permissions.js';
import { withTransaction } from '../../repositories/base.js';
import type { Store } from '../../repositories/store.js';
import type { Device } from '../../types/index.js';

export function listDevices(store: Store, principal: Principal): Device[] {
  return store.devices().filter((row) => row.userId === principal.userId);
}

export async function revokeDevice(
  store: Store,
  principal: Principal,
  deviceId: string,
): Promise<void> {
  const device = store
    .devices()
    .find((row) => row.id === deviceId && row.userId === principal.userId);
  if (device === undefined) throw notFound();
  await withTransaction(store, async (tx) => {
    tx.saveDevice({ ...device, revoked: true });
    for (const family of tx.refresh()) {
      if (family.deviceId === deviceId)
        tx.saveRefresh({ ...family, revoked: true });
    }
    tx.recordAudit({
      actorId: principal.userId,
      action: 'revoke_device',
      target: deviceId,
      before: { revoked: false },
      after: { revoked: true },
    });
  });
}
