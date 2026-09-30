import type { Sql } from './sql.js';

/// A reduced organisation window also shortens existing ciphertext expiry.
export async function applyRetention(sql: Sql, days: number): Promise<void> {
  await sql.write(
    'UPDATE organisations SET retention_days=$1 WHERE retention_days <> $1',
    [days],
  );
  await sql.write(
    'UPDATE projects SET retention_days=$1 WHERE retention_days > $1',
    [days],
  );
  await sql.write(
    "UPDATE relay_packages SET expires_at=created_at+$1*interval '1 day' WHERE expires_at > created_at+$1*interval '1 day'",
    [days],
  );
  await sql.write(
    'UPDATE relay_acknowledgements a SET expires_at=p.expires_at FROM relay_packages p WHERE p.id=a.package_id AND a.expires_at <> p.expires_at',
  );
}

/// One snapshot of every metadata table, excluding ciphertext and credentials.
export async function exportMetadata(
  sql: Sql,
): Promise<Record<string, unknown>> {
  const rows = await sql.rows<{
    metadata: Record<string, unknown>;
  }>(`SELECT json_build_object(
    'organisations',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM organisations r),
    'accounts',(SELECT coalesce(jsonb_agg(to_jsonb(r)-'password_hash'),'[]'::jsonb) FROM users r),
    'devices',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM devices r),
    'projects',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM projects r),
    'memberships',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM project_members r),
    'audit',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM audit_events r),
    'security',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM security_events r),
    'packageMetadata',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM relay_packages r),
    'acknowledgements',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM relay_acknowledgements r),
    'vectors',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM relay_vectors r),
    'invitations',(SELECT coalesce(jsonb_agg(to_jsonb(r)-'token_hash'),'[]'::jsonb) FROM invitations r),
    'refreshFamilies',(SELECT coalesce(jsonb_agg(to_jsonb(r)-'token_hash'),'[]'::jsonb) FROM refresh_families r),
    'usage',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM ai_usage r),
    'idempotency',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM idempotency_keys r),
    'lockouts',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM login_lockouts r),
    'configuration',(SELECT coalesce(jsonb_agg(to_jsonb(r)-'fingerprint'),'[]'::jsonb) FROM runtime_settings r),
    'schema',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM schema_migrations r)
  ) AS metadata`);
  const row = rows[0];
  if (row === undefined) throw new Error('Metadata export failed.');
  return row.metadata;
}

/// Each delete is bounded and runs inside the purge transaction.
export async function purgeTransient(
  sql: Sql,
  now: Date,
  limit: number,
): Promise<number> {
  let deleted = 0;
  for (const [table, key] of [
    ['invitations', 'token_hash'],
    ['refresh_families', 'id'],
    ['idempotency_keys', 'key'],
    ['login_lockouts', 'key'],
  ] as const) {
    const remaining = limit - deleted;
    if (remaining === 0) break;
    const rows = await sql.rows<{ key: string }>(
      `DELETE FROM ${table} WHERE ${key} IN (SELECT ${key} FROM ${table} WHERE expires_at <= $1 ORDER BY expires_at,${key} LIMIT $2) RETURNING ${key} AS key`,
      [now.toISOString(), remaining],
    );
    deleted += rows.length;
  }
  return deleted;
}

/// The confirmed administrative command removes deployment state. Normal
/// runtime credentials lack TRUNCATE; append-only event triggers stay enabled.
export async function destroyDeployment(
  sql: Sql,
  organisationId: string,
): Promise<string[]> {
  const orgs = await sql.rows<{ id: string }>(
    'SELECT id FROM organisations ORDER BY id',
  );
  if (orgs.length !== 1 || orgs[0]?.id !== organisationId)
    throw new Error(
      'Destroy requires a single matching organisation deployment.',
    );
  await sql.write(
    'TRUNCATE TABLE relay_blobs,relay_acknowledgements,relay_packages,relay_vectors,project_members,ai_usage,projects,invitations,refresh_families,devices,users,organisations,audit_events,security_events,idempotency_keys,login_lockouts,runtime_settings',
  );
  return [
    'organisation',
    'users',
    'devices',
    'projects',
    'memberships',
    'package-metadata',
    'relay-ciphertext',
    'acknowledgements',
    'vectors',
    'invitations',
    'refresh-families',
    'usage',
    'audit',
    'security',
    'idempotency',
    'lockouts',
    'configuration-metadata',
  ];
}
