import type { Project, Membership } from '../types/index.js';
import type { Sql } from './sql.js';

export function projectRepository(sql: Sql) {
  return {
    projects: () =>
      sql.rows<Project>(
        'SELECT id,organisation_id AS "organisationId",name,relay_enabled AS "relayEnabled",never_relay AS "neverRelay",retention_days AS "retentionDays" FROM projects ORDER BY id',
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
    members: () =>
      sql.rows<Membership>(
        'SELECT project_id AS "projectId",user_id AS "userId",context_scope AS "contextScope" FROM project_members ORDER BY project_id,user_id',
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
