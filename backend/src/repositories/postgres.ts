import type { AppPool, SqlConnection } from '../db/pool.js';
import type { Repository } from './repository.js';
import { identityRepository } from './postgres-identity.js';
import { projectRepository } from './postgres-projects.js';
import { eventRepository } from './postgres-events.js';
import { relayRepository } from './postgres-relay.js';
import { Sql } from './sql.js';

/// Every write reaches Postgres before its service confirms it to a device.
export function createPostgresRepository(pool: AppPool): Repository {
  return repository(pool, pool);
}

function repository(connection: SqlConnection, pool?: AppPool): Repository {
  const sql = new Sql(connection);
  const result: Repository = {
    ...identityRepository(sql),
    ...projectRepository(sql),
    ...eventRepository(sql),
    ...relayRepository(sql),
    withTransaction: async <T>(work: (store: Repository) => Promise<T>) => {
      if (pool === undefined) return work(result);
      return pool.transaction(async (tx) => {
        // One deployment serves one organisation. The transaction
        // lock protects quota, refresh rotation and idempotency across replicas.
        await tx.query('SELECT pg_advisory_xact_lock($1)', [744278]);
        return work(repository(tx));
      });
    },
    destroyOrganisation: async (organisationId: string) => {
      if (pool !== undefined) {
        return result.withTransaction(async (tx) =>
          tx.destroyOrganisation(organisationId),
        );
      }
      const values = [organisationId];
      await sql.write(
        'DELETE FROM relay_packages WHERE project_id IN(SELECT id FROM projects WHERE organisation_id=$1)',
        values,
      );
      await sql.write(
        'DELETE FROM relay_vectors WHERE project_id IN(SELECT id FROM projects WHERE organisation_id=$1)',
        values,
      );
      await sql.write(
        'DELETE FROM project_members WHERE project_id IN(SELECT id FROM projects WHERE organisation_id=$1)',
        values,
      );
      await sql.write(
        'DELETE FROM ai_usage WHERE project_id IN(SELECT id FROM projects WHERE organisation_id=$1)',
        values,
      );
      await sql.write('DELETE FROM projects WHERE organisation_id=$1', values);
      await sql.write(
        'DELETE FROM invitations WHERE user_id IN(SELECT id FROM users WHERE organisation_id=$1)',
        values,
      );
      await sql.write(
        'DELETE FROM refresh_families WHERE user_id IN(SELECT id FROM users WHERE organisation_id=$1)',
        values,
      );
      await sql.write(
        'DELETE FROM devices WHERE user_id IN(SELECT id FROM users WHERE organisation_id=$1)',
        values,
      );
      await sql.write('DELETE FROM users WHERE organisation_id=$1', values);
      await sql.write('DELETE FROM organisations WHERE id=$1', values);
      return [
        'organisation',
        'users',
        'devices',
        'projects',
        'memberships',
        'package-metadata',
      ];
    },
  };
  return result;
}
