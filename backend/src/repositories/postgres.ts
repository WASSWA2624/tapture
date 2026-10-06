import type { AppPool, SqlConnection } from '../db/pool.js';
import type { Repository } from './repository.js';
import { identityRepository } from './postgres-identity.js';
import { projectRepository } from './postgres-projects.js';
import { eventRepository } from './postgres-events.js';
import { relayRepository } from './postgres-relay.js';
import { settingsRepository } from './postgres-settings.js';
import { aiRepository } from './postgres-ai.js';
import { Sql } from './sql.js';
import {
  applyRetention,
  destroyDeployment,
  exportMetadata,
  purgeTransient,
} from './postgres-maintenance.js';

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
    ...settingsRepository(sql),
    ...aiRepository(sql),
    applyRetention: (days) => applyRetention(sql, days),
    purgeTransient: (now, limit) => purgeTransient(sql, now, limit),
    exportMetadata: () => exportMetadata(sql),
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
      return destroyDeployment(sql, organisationId);
    },
  };
  return result;
}
