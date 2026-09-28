import { randomUUID } from 'node:crypto';
import type { AuditEvent } from '../types/index.js';
import type { UsageRow } from './store.js';
import type { Sql } from './sql.js';

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
        event.after,
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
    addUsage: (row: UsageRow) =>
      sql.write(
        'INSERT INTO ai_usage(id,project_id,user_id,model,byte_size,duration_ms,outcome,cost,at) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)',
        [
          randomUUID(),
          row.projectId,
          row.userId,
          row.model,
          row.byteSize,
          row.durationMs,
          row.outcome,
          row.cost,
          row.at,
        ],
      ),
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
