import type { RelayPackage } from '../types/index.js';
import type { Ack, IdempotentResult } from './store.js';
import type { Sql } from './sql.js';

export function relayRepository(sql: Sql) {
  return {
    expiredPackages: (now: Date, limit: number) =>
      sql.rows<RelayPackage>(
        'SELECT id,project_id AS "projectId",author_device_id AS "authorDeviceId",byte_size AS "byteSize",created_at AS "createdAt",expires_at AS "expiresAt",storage_ref AS "storageRef" FROM relay_packages WHERE expires_at <= $1 ORDER BY expires_at,id LIMIT $2',
        [now.toISOString(), limit],
      ),
    packages: () =>
      sql.rows<RelayPackage>(
        'SELECT id,project_id AS "projectId",author_device_id AS "authorDeviceId",byte_size AS "byteSize",created_at AS "createdAt",expires_at AS "expiresAt",storage_ref AS "storageRef" FROM relay_packages ORDER BY created_at,id',
      ),
    addPackage: async (row: RelayPackage, bytes: Buffer) => {
      await sql.write(
        'INSERT INTO relay_packages(id,project_id,author_device_id,byte_size,created_at,expires_at,storage_ref) VALUES($1,$2,$3,$4,$5,$6,$7)',
        [
          row.id,
          row.projectId,
          row.authorDeviceId,
          row.byteSize,
          row.createdAt,
          row.expiresAt,
          row.storageRef,
        ],
      );
      await sql.write(
        'INSERT INTO relay_blobs(package_id,storage_ref,ciphertext) VALUES($1,$2,$3)',
        [row.id, row.storageRef, bytes],
      );
    },
    removePackage: (id: string) =>
      sql.write('DELETE FROM relay_packages WHERE id=$1', [id]),
    blob: async (ref: string) =>
      (
        await sql.rows<{ bytes: Buffer }>(
          'SELECT ciphertext AS bytes FROM relay_blobs WHERE storage_ref=$1',
          [ref],
        )
      )[0]?.bytes,
    acks: () =>
      sql.rows<Ack>(
        'SELECT package_id AS "packageId",device_id AS "deviceId" FROM relay_acknowledgements ORDER BY package_id,device_id',
      ),
    addAck: (row: Ack) =>
      sql.write(
        'INSERT INTO relay_acknowledgements(package_id,device_id) VALUES($1,$2) ON CONFLICT DO NOTHING',
        [row.packageId, row.deviceId],
      ),
    vectors: () =>
      sql.rows<{ projectId: string; deviceId: string; counter: number }>(
        'SELECT project_id AS "projectId",device_id AS "deviceId",counter FROM relay_vectors ORDER BY project_id,device_id',
      ),
    bumpVector: async (projectId: string, deviceId: string) => {
      const rows = await sql.rows<{ counter: number }>(
        'INSERT INTO relay_vectors(project_id,device_id,counter) VALUES($1,$2,1) ON CONFLICT(project_id,device_id) DO UPDATE SET counter=relay_vectors.counter+1 RETURNING counter',
        [projectId, deviceId],
      );
      return rows[0]?.counter ?? 0;
    },
    idempotency: async (key: string) =>
      (
        await sql.rows<IdempotentResult>(
          'SELECT status,body FROM idempotency_keys WHERE key=$1 AND expires_at > now()',
          [key],
        )
      )[0],
    saveIdempotency: (key: string, result: IdempotentResult) =>
      sql.write(
        "INSERT INTO idempotency_keys(key,status,body,expires_at) VALUES($1,$2,$3,now()+interval '90 days') ON CONFLICT(key) DO NOTHING",
        [key, result.status, JSON.stringify(result.body)],
      ),
  };
}
