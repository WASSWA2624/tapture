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
import type { Repository as Store } from '../../repositories/repository.js';
import type { Project, RelayPackage } from '../../types/index.js';
import { withinCeiling } from './quota.js';
import { visibleProject } from '../projects.js';
async function relayProject(
  store: Store,
  principal: Principal,
  projectId: string,
): Promise<Project> {
  const project = await visibleProject(store, principal, projectId);
  if (!project.relayEnabled || project.neverRelay)
    throw invalidRequest('Relay is not enabled for this project.');
  return project;
}
/// Records a refused relay access on a store whose writes are not about to be
/// rolled back with the refusal.
async function recordDenial(
  store: Store,
  principal: Principal,
  projectId: string,
): Promise<void> {
  await store.recordSecurity({
    actorId: principal.userId,
    action: 'relay_denied',
    target: projectId,
    before: null,
    after: null,
  });
}
async function requireProject(
  store: Store,
  principal: Principal,
  projectId: string,
): Promise<Project> {
  try {
    return await relayProject(store, principal, projectId);
  } catch (error) {
    await recordDenial(store, principal, projectId);
    throw error;
  }
}
/// Runs [work] in one transaction. A relay refusal inside it rolls the work
/// back, and its security event is recorded once the transaction has ended.
async function relayTransaction<T>(
  store: Store,
  principal: Principal,
  work: (
    tx: Store,
    requireRelay: (projectId: string) => Promise<Project>,
  ) => Promise<T>,
): Promise<T> {
  const denial: { projectId?: string } = {};
  try {
    return await withTransaction(store, (tx) =>
      work(tx, async (projectId) => {
        try {
          return await relayProject(tx, principal, projectId);
        } catch (error) {
          denial.projectId = projectId;
          throw error;
        }
      }),
    );
  } catch (error) {
    if (denial.projectId !== undefined) {
      await recordDenial(store, principal, denial.projectId);
    }
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
  if (!can(principal, 'relay')) throw notFound();
  return relayTransaction(store, principal, async (tx, requireRelay) => {
    const project = await requireRelay(projectId);
    const key = `upload:${principal.organisationId}:${projectId}:${principal.deviceId}:${idempotencyKey}`;
    const prior = await tx.idempotency(key);
    if (prior !== undefined) return prior.body as RelayPackage;
    if (bytes.length > config.packageMaxBytes) throw payloadTooLarge();
    const used = (await tx.packages())
      .filter((row) => row.projectId === projectId)
      .reduce((sum, row) => sum + row.byteSize, 0);
    if (!withinCeiling(used, bytes.length, config.storageCeilingBytes)) {
      throw quotaExceeded();
    }
    const organisationProjects = new Set(
      (await tx.projects())
        .filter((row) => row.organisationId === principal.organisationId)
        .map((row) => row.id),
    );
    const organisationBytes = (await tx.packages())
      .filter((row) => organisationProjects.has(row.projectId))
      .reduce((total, row) => total + row.byteSize, 0);
    if (
      !withinCeiling(
        organisationBytes,
        bytes.length,
        config.organisationStorageCeilingBytes,
      )
    )
      throw quotaExceeded();
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
    await tx.addPackage(row, bytes);
    await tx.bumpVector(projectId, principal.deviceId);
    await tx.recordAudit({
      actorId: principal.userId,
      action: 'relay_upload',
      target: id,
      before: null,
      after: { byteSize: bytes.length },
    });
    await tx.saveIdempotency(key, {
      status: 201,
      body: meta(row),
    });
    return meta(row);
  });
}
export async function listPackages(
  store: Store,
  principal: Principal,
  projectId: string,
  query?: {
    cursor?: string;
    limit?: number;
  },
): Promise<{
  items: RelayPackage[];
  nextCursor: string | null;
}> {
  if (!can(principal, 'relay')) throw notFound();
  await requireProject(store, principal, projectId);
  await store.recordAudit({
    actorId: principal.userId,
    action: 'relay_list',
    target: projectId,
    before: null,
    after: null,
  });
  const acknowledged = new Set(
    (await store.acks())
      .filter((row) => row.deviceId === principal.deviceId)
      .map((row) => row.packageId),
  );
  const all = (await store.packages())
    .filter(
      (row) =>
        row.projectId === projectId &&
        !acknowledged.has(row.id) &&
        Date.parse(row.expiresAt) > Date.now(),
    )
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
export async function readPackage(
  store: Store,
  principal: Principal,
  projectId: string,
  packageId: string,
): Promise<{
  meta: RelayPackage;
  bytes: Buffer;
}> {
  if (!can(principal, 'relay')) throw notFound();
  await requireProject(store, principal, projectId);
  const row = (await store.packages()).find(
    (item) => item.id === packageId && item.projectId === projectId,
  );
  if (row === undefined || Date.parse(row.expiresAt) <= Date.now())
    throw notFound();
  await store.recordAudit({
    actorId: principal.userId,
    action: 'relay_download',
    target: packageId,
    before: null,
    after: null,
  });
  const bytes = await store.blob(row.storageRef);
  if (bytes === undefined) throw notFound();
  return { meta: meta(row), bytes };
}
export async function acknowledge(
  store: Store,
  principal: Principal,
  packageIds: string[],
  idempotencyKey: string,
): Promise<{
  acknowledged: string[];
}> {
  if (!can(principal, 'relay')) throw notFound();
  return relayTransaction(store, principal, async (tx, requireRelay) => {
    const key = `ack:${principal.organisationId}:${principal.deviceId}:${idempotencyKey}`;
    const prior = await tx.idempotency(key);
    if (prior !== undefined) return prior.body as { acknowledged: string[] };
    const acknowledged: string[] = [];
    for (const packageId of packageIds) {
      const row = (await tx.packages()).find((item) => item.id === packageId);
      if (row === undefined) {
        acknowledged.push(packageId);
        continue;
      }
      await requireRelay(row.projectId);
      if (
        (await tx.acks()).some(
          (ack) =>
            ack.packageId === packageId && ack.deviceId === principal.deviceId,
        )
      ) {
        acknowledged.push(packageId);
        continue;
      }
      await tx.addAck({ packageId, deviceId: principal.deviceId });
      await tx.bumpVector(row.projectId, principal.deviceId);
      const members = (await tx.members()).filter(
        (item) => item.projectId === row.projectId,
      );
      const devices = (await tx.devices()).filter(
        (device) =>
          !device.revoked &&
          members.some((member) => member.userId === device.userId),
      );
      const acked = new Set(
        (await tx.acks())
          .filter((ack) => ack.packageId === packageId)
          .map((ack) => ack.deviceId),
      );
      if (devices.every((device) => acked.has(device.id))) {
        await tx.removePackage(packageId);
      }
      await tx.recordAudit({
        actorId: principal.userId,
        action: 'relay_ack',
        target: packageId,
        before: null,
        after: { purged: devices.every((device) => acked.has(device.id)) },
      });
      acknowledged.push(packageId);
    }
    const body = { acknowledged };
    await tx.saveIdempotency(key, { status: 200, body });
    return body;
  });
}
export async function relayState(
  store: Store,
  principal: Principal,
  projectId: string,
): Promise<VersionVector> {
  if (!can(principal, 'relay')) throw notFound();
  await requireProject(store, principal, projectId);
  const vector: VersionVector = {};
  for (const row of await store.vectors()) {
    if (row.projectId === projectId) vector[row.deviceId] = row.counter;
  }
  return mergeVectors(vector, {});
}
export function packageDigest(bytes: Buffer): string {
  return createHash('sha256').update(bytes).digest('hex');
}
