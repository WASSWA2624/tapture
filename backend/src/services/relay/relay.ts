import { createHash, randomUUID } from 'node:crypto';
import type { AppConfig } from '../../config/schema.js';
import { can, type Principal } from '../../domain/permissions.js';
import {
  invalidRequest,
  notFound,
  payloadTooLarge,
  quotaExceeded,
} from '../../domain/errors.js';
import {
  mergeVectors,
  type VersionVector,
} from '../../domain/version_vector.js';
import { withTransaction } from '../../repositories/base.js';
import type { Store } from '../../repositories/store.js';
import type { RelayPackage } from '../../types/index.js';
import { withinCeiling } from './quota.js';
import { visibleProject } from '../projects.js';

function requireProject(store: Store, principal: Principal, projectId: string) {
  try {
    return visibleProject(store, principal, projectId);
  } catch (error) {
    store.recordSecurity({
      actorId: principal.userId,
      action: 'relay_denied',
      target: projectId,
      before: null,
      after: null,
    });
    throw error;
  }
}

function meta(row: RelayPackage): RelayPackage {
  return {
    id: row.id,
    projectId: row.projectId,
    authorDeviceId: row.authorDeviceId,
    byteSize: row.byteSize,
    createdAt: row.createdAt,
    expiresAt: row.expiresAt,
    storageRef: row.storageRef,
  };
}

export async function uploadPackage(
  store: Store,
  config: AppConfig,
  principal: Principal,
  projectId: string,
  bytes: Buffer,
  idempotencyKey: string,
): Promise<RelayPackage> {
  const prior = store.idempotency(`upload:${idempotencyKey}`);
  if (prior !== undefined) return prior.body as RelayPackage;
  if (!can(principal, 'relay')) throw notFound();
  const project = requireProject(store, principal, projectId);
  if (!project.relayEnabled || project.neverRelay) {
    throw invalidRequest('Relay is not enabled for this project.');
  }
  if (bytes.length > config.packageMaxBytes) throw payloadTooLarge();
  const used = store
    .packages()
    .filter((row) => row.projectId === projectId)
    .reduce((sum, row) => sum + row.byteSize, 0);
  if (!withinCeiling(used, bytes.length, config.storageCeilingBytes)) {
    throw quotaExceeded();
  }
  const id = randomUUID();
  const createdAt = new Date().toISOString();
  const expiresAt = new Date(
    Date.now() + project.retentionDays * 24 * 60 * 60 * 1000,
  ).toISOString();
  const row: RelayPackage = {
    id,
    projectId,
    authorDeviceId: principal.deviceId,
    byteSize: bytes.length,
    createdAt,
    expiresAt,
    storageRef: `blob:${id}`,
  };
  await withTransaction(store, async (tx) => {
    tx.addPackage(row, bytes);
    tx.bumpVector(projectId, principal.deviceId);
    tx.recordAudit({
      actorId: principal.userId,
      action: 'relay_upload',
      target: id,
      before: null,
      after: { byteSize: bytes.length },
    });
    tx.saveIdempotency(`upload:${idempotencyKey}`, {
      status: 201,
      body: meta(row),
    });
  });
  return meta(row);
}

export function listPackages(
  store: Store,
  principal: Principal,
  projectId: string,
  query?: { cursor?: string; limit?: number },
): { items: RelayPackage[]; nextCursor: string | null } {
  if (!can(principal, 'relay')) throw notFound();
  requireProject(store, principal, projectId);
  store.recordAudit({
    actorId: principal.userId,
    action: 'relay_list',
    target: projectId,
    before: null,
    after: null,
  });
  const all = store
    .packages()
    .filter((row) => row.projectId === projectId)
    .map(meta);
  const limit = query?.limit ?? 50;
  const start =
    query?.cursor === undefined
      ? 0
      : all.findIndex((row) => row.id === query.cursor) + 1;
  const items = all.slice(start, start + limit);
  const last = items.at(-1);
  const hasMore = start + items.length < all.length;
  return { items, nextCursor: hasMore ? (last?.id ?? null) : null };
}

export function readPackage(
  store: Store,
  principal: Principal,
  projectId: string,
  packageId: string,
): { meta: RelayPackage; bytes: Buffer } {
  if (!can(principal, 'relay')) throw notFound();
  requireProject(store, principal, projectId);
  const row = store
    .packages()
    .find((item) => item.id === packageId && item.projectId === projectId);
  if (row === undefined) throw notFound();
  store.recordAudit({
    actorId: principal.userId,
    action: 'relay_download',
    target: packageId,
    before: null,
    after: null,
  });
  const bytes = store.blob(row.storageRef);
  if (bytes === undefined) throw notFound();
  return { meta: meta(row), bytes };
}

export async function acknowledge(
  store: Store,
  principal: Principal,
  packageIds: string[],
  idempotencyKey: string,
): Promise<{ acknowledged: string[] }> {
  const prior = store.idempotency(`ack:${idempotencyKey}`);
  if (prior !== undefined) return prior.body as { acknowledged: string[] };
  if (!can(principal, 'relay')) throw notFound();
  const result = await withTransaction(store, async (tx) => {
    const acknowledged: string[] = [];
    for (const packageId of packageIds) {
      const row = tx.packages().find((item) => item.id === packageId);
      if (row === undefined) {
        acknowledged.push(packageId);
        continue;
      }
      requireProject(tx, principal, row.projectId);
      tx.addAck({ packageId, deviceId: principal.deviceId });
      const members = tx
        .members()
        .filter((item) => item.projectId === row.projectId);
      const devices = tx
        .devices()
        .filter(
          (device) =>
            !device.revoked &&
            members.some((member) => member.userId === device.userId),
        );
      const acked = new Set(
        tx
          .acks()
          .filter((ack) => ack.packageId === packageId)
          .map((ack) => ack.deviceId),
      );
      if (devices.every((device) => acked.has(device.id))) {
        tx.removePackage(packageId);
      }
      acknowledged.push(packageId);
    }
    const body = { acknowledged };
    tx.saveIdempotency(`ack:${idempotencyKey}`, { status: 200, body });
    return body;
  });
  return result;
}

export function relayState(
  store: Store,
  principal: Principal,
  projectId: string,
): VersionVector {
  if (!can(principal, 'relay')) throw notFound();
  requireProject(store, principal, projectId);
  const vector: VersionVector = {};
  for (const row of store.vectors()) {
    if (row.projectId === projectId) vector[row.deviceId] = row.counter;
  }
  return mergeVectors(vector, {});
}

export function packageDigest(bytes: Buffer): string {
  return createHash('sha256').update(bytes).digest('hex');
}
