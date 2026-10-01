import { randomUUID } from 'node:crypto';
import type { AuditEvent } from '../types/index.js';
import type { QuotaUsage, UsageRow } from './usage.js';
import type { Sql } from './sql.js';
import type { UsageQuery } from './queries.js';

export function eventRepository(sql: Sql) {
  const addEvent = (
    table: 'audit_events' | 'security_events',
    event: Omit<AuditEvent, 'id' | 'at'>,
  ) =>
    sql.write(
      `INSERT INTO ${table}(id,at,actor_id,action,target,before,after) VALUES($1,$2,$3,$4,$5,$6,$7)`,
      [
        randomUUID(),
        new Date().toISOString(),
        event.actorId,
        event.action,
        event.target,
        event.before,
        table === 'audit_events'
          ? { outcome: 'applied', ...event.after }
          : event.after,
      ],
    );
  return {
    audit: () =>
      sql.rows<AuditEvent>(
        'SELECT id,at,actor_id AS "actorId",action,target,before,after FROM audit_events ORDER BY at,id',
      ),
    security: () =>
      sql.rows<AuditEvent>(
        'SELECT id,at,actor_id AS "actorId",action,target,before,after FROM security_events ORDER BY at,id',
      ),
    recordAudit: (event: Omit<AuditEvent, 'id' | 'at'>) =>
      addEvent('audit_events', event),
    recordSecurity: (event: Omit<AuditEvent, 'id' | 'at'>) =>
      addEvent('security_events', event),
    usage: () =>
      sql.rows<UsageRow>(
        'SELECT project_id AS "projectId",user_id AS "userId",model,byte_size AS "byteSize",duration_ms AS "durationMs",outcome,cost,at FROM ai_usage ORDER BY at,id',
      ),
    usagePage: (query: UsageQuery) =>
      sql.rows<UsageRow & { id: string }>(
        'SELECT id,project_id AS "projectId",user_id AS "userId",model,byte_size AS "byteSize",duration_ms AS "durationMs",outcome,cost,at FROM ai_usage WHERE project_id=$1 AND user_id=$2 AND at >= $3 AND at <= $4 AND ($5::text IS NULL OR id>$5) ORDER BY id LIMIT $6',
        [
          query.projectId,
          query.userId,
          query.from,
          query.to,
          query.cursor ?? null,
          query.limit ?? null,
        ],
      ),
    addUsage: async (row: UsageRow) => {
      const id = randomUUID();
      await sql.write(
        'INSERT INTO ai_usage(id,project_id,user_id,model,byte_size,duration_ms,outcome,cost,at) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)',
        [
          id,
          row.projectId,
          row.userId,
          row.model,
          row.byteSize,
          row.durationMs,
          row.outcome,
          row.cost,
          row.at,
        ],
      );
      return id;
    },
    finishUsage: (
      id: string,
      outcome: string,
      durationMs: number,
      model: string,
    ) =>
      sql.write(
        'UPDATE ai_usage SET outcome=$2,duration_ms=$3,model=$4 WHERE id=$1',
        [id, outcome, durationMs, model],
      ),
    quotaUsage: async (
      organisationId: string,
      projectId: string,
      dayFrom: string,
      dayTo: string,
    ): Promise<QuotaUsage> => {
      // Aggregate in Postgres rather than copying the complete usage history
      // into every request. Pending reservations count against every limit.
      const rows = await sql.rows<{
        project: QuotaUsage['project'];
        organisation: QuotaUsage['organisation'];
      }>(
        `SELECT json_build_object(
          'requests',count(*) FILTER (WHERE u.project_id=$2),
          'dailyRequests',count(*) FILTER (WHERE u.project_id=$2 AND u.at >= $3 AND u.at < $4),
          'cost',coalesce(sum(u.cost) FILTER (WHERE u.project_id=$2),0),
          'dailyCost',coalesce(sum(u.cost) FILTER (WHERE u.project_id=$2 AND u.at >= $3 AND u.at < $4),0)
        ) AS project,json_build_object(
          'requests',count(*),
          'dailyRequests',count(*) FILTER (WHERE u.at >= $3 AND u.at < $4),
          'cost',coalesce(sum(u.cost),0),
          'dailyCost',coalesce(sum(u.cost) FILTER (WHERE u.at >= $3 AND u.at < $4),0)
        ) AS organisation FROM ai_usage u JOIN projects p ON p.id=u.project_id WHERE p.organisation_id=$1`,
        [organisationId, projectId, dayFrom, dayTo],
      );
      const row = rows[0];
      if (row === undefined) throw new Error('Missing usage aggregate.');
      return row;
    },
    schemaHistory: () =>
      sql.rows<{ name: string; checksum: string }>(
        'SELECT name,checksum FROM schema_migrations ORDER BY name',
      ),
    recordMigration: (name: string, checksum: string) =>
      sql.write('INSERT INTO schema_migrations(name,checksum) VALUES($1,$2)', [
        name,
        checksum,
      ]),
  };
}
