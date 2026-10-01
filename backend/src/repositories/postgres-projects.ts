import type { Project, Membership } from '../types/index.js';
import type { Sql } from './sql.js';
import type { MembershipQuery, ProjectQuery } from './queries.js';

export function projectRepository(sql: Sql) {
  return {
    projects: (query?: ProjectQuery) =>
      sql.rows<Project>(
        'SELECT p.id,p.organisation_id AS "organisationId",p.name,p.relay_enabled AS "relayEnabled",p.never_relay AS "neverRelay",p.retention_days AS "retentionDays" FROM projects p WHERE ($1::text IS NULL OR p.id=$1) AND ($2::text IS NULL OR p.organisation_id=$2) AND ($3::text IS NULL OR EXISTS (SELECT 1 FROM project_members m WHERE m.project_id=p.id AND m.user_id=$3)) AND ($4::text IS NULL OR p.id>$4) ORDER BY p.id LIMIT $5',
        [
          query?.id ?? null,
          query?.organisationId ?? null,
          query?.memberUserId ?? null,
          query?.cursor ?? null,
          query?.limit ?? null,
        ],
      ),
    addProject: (row: Project) =>
      sql.write(
        'INSERT INTO projects(id,organisation_id,name,relay_enabled,never_relay,retention_days) VALUES($1,$2,$3,$4,$5,$6)',
        [
          row.id,
          row.organisationId,
          row.name,
          row.relayEnabled,
          row.neverRelay,
          row.retentionDays,
        ],
      ),
    saveProject: (row: Project) =>
      sql.write(
        'UPDATE projects SET name=$2,relay_enabled=$3,never_relay=$4,retention_days=$5 WHERE id=$1',
        [row.id, row.name, row.relayEnabled, row.neverRelay, row.retentionDays],
      ),
    members: (query?: MembershipQuery) =>
      sql.rows<Membership>(
        'SELECT project_id AS "projectId",user_id AS "userId",context_scope AS "contextScope" FROM project_members WHERE ($1::text IS NULL OR project_id=$1) AND ($2::text IS NULL OR user_id=$2) AND ($3::text IS NULL OR user_id>$3) ORDER BY project_id,user_id LIMIT $4',
        [
          query?.projectId ?? null,
          query?.userId ?? null,
          query?.cursor ?? null,
          query?.limit ?? null,
        ],
      ),
    addMember: (row: Membership) =>
      sql.write(
        'INSERT INTO project_members(project_id,user_id,context_scope) VALUES($1,$2,$3)',
        [row.projectId, row.userId, row.contextScope],
      ),
    removeMember: (projectId: string, userId: string) =>
      sql.write(
        'DELETE FROM project_members WHERE project_id=$1 AND user_id=$2',
        [projectId, userId],
      ),
  };
}
