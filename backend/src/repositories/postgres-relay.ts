import type { RelayPackage } from '../types/index.js';
import type { Ack, IdempotentResult } from './store.js';
import type { Sql } from './sql.js';
import type { AckQuery, PackageQuery } from './queries.js';

export function relayRepository(sql: Sql) {
  return {
    relayQuotaUsage: async (
      organisationId: string,
      projectId: string,
    ): Promise<{ projectBytes: number; organisationBytes: number }> => {
      const rows = await sql.rows<{
        projectBytes: number;
        organisationBytes: number;
      }>(
        'SELECT coalesce(sum(r.byte_size) FILTER (WHERE r.project_id=$2),0)::float8 AS "projectBytes",coalesce(sum(r.byte_size),0)::float8 AS "organisationBytes" FROM relay_packages r JOIN projects p ON p.id=r.project_id WHERE p.organisation_id=$1',
        [organisationId, projectId],
      );
      const row = rows[0];
      if (row === undefined)
        throw new Error('Missing relay storage aggregate.');
      return row;
    },
    storageUsage: async (): Promise<Record<string, number>> => {
      const rows = await sql.rows<{ projectId: string; bytes: number }>(
        'SELECT project_id AS "projectId",sum(byte_size)::float8 AS bytes FROM relay_packages GROUP BY project_id',
      );
      return Object.fromEntries(rows.map((row) => [row.projectId, row.bytes]));
    },
    expiredPackages: (now: Date, limit: number) =>
      sql.rows<RelayPackage>(
        'SELECT id,project_id AS "projectId",author_device_id AS "authorDeviceId",byte_size AS "byteSize",created_at AS "createdAt",expires_at AS "expiresAt",storage_ref AS "storageRef" FROM relay_packages WHERE expires_at <= $1 ORDER BY expires_at,id LIMIT $2',
        [now.toISOString(), limit],
      ),
    packages: (query?: PackageQuery) =>
      sql.rows<RelayPackage>(
        'SELECT r.id,r.project_id AS "projectId",r.author_device_id AS "authorDeviceId",r.byte_size AS "byteSize",r.created_at AS "createdAt",r.expires_at AS "expiresAt",r.storage_ref AS "storageRef" FROM relay_packages r WHERE ($1::text IS NULL OR r.id=$1) AND ($2::text IS NULL OR r.project_id=$2) AND ($3::text IS NULL OR NOT EXISTS (SELECT 1 FROM relay_acknowledgements a WHERE a.package_id=r.id AND a.device_id=$3)) AND ($4::timestamptz IS NULL OR r.expires_at>$4) AND ($5::timestamptz IS NULL OR (r.created_at,r.id)>($5,$6::text)) ORDER BY r.created_at,r.id LIMIT $7',
        [
          query?.id ?? null,
          query?.projectId ?? null,
          query?.unacknowledgedDeviceId ?? null,
          query?.activeAfter ?? null,
          query?.after?.createdAt ?? null,
          query?.after?.id ?? null,
          query?.limit ?? null,
        ],
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
    acks: (query?: AckQuery) =>
      sql.rows<Ack>(
        'SELECT package_id AS "packageId",device_id AS "deviceId" FROM relay_acknowledgements WHERE ($1::text IS NULL OR package_id=$1) AND ($2::text IS NULL OR device_id=$2) ORDER BY package_id,device_id',
        [query?.packageId ?? null, query?.deviceId ?? null],
      ),
    addAck: (row: Ack) =>
      sql.write(
        'INSERT INTO relay_acknowledgements(package_id,device_id,expires_at) SELECT $1,$2,expires_at FROM relay_packages WHERE id=$1 ON CONFLICT DO NOTHING',
        [row.packageId, row.deviceId],
      ),
    vectors: (projectId?: string) =>
      sql.rows<{ projectId: string; deviceId: string; counter: number }>(
        'SELECT project_id AS "projectId",device_id AS "deviceId",counter FROM relay_vectors WHERE ($1::text IS NULL OR project_id=$1) ORDER BY project_id,device_id',
        [projectId ?? null],
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
    saveIdempotency: (
      key: string,
      result: IdempotentResult,
      expiresAt = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
    ) =>
      sql.write(
        'INSERT INTO idempotency_keys(key,status,body,expires_at) VALUES($1,$2,$3,$4) ON CONFLICT(key) DO UPDATE SET status=EXCLUDED.status,body=EXCLUDED.body,created_at=now(),expires_at=EXCLUDED.expires_at WHERE idempotency_keys.expires_at <= now()',
        [key, result.status, JSON.stringify(result.body), expiresAt],
      ),
  };
}
