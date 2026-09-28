import type { Organisation, User, Device } from '../types/index.js';
import type { RefreshFamily, Invite } from './store.js';
import type { Role } from '../domain/permissions.js';
import type { Sql } from './sql.js';

export function identityRepository(sql: Sql) {
  return {
    orgs: () =>
      sql.rows<Organisation>(
        'SELECT id, name, self_register AS "selfRegister", retention_days AS "retentionDays" FROM organisations ORDER BY id',
      ),
    addOrg: (row: Organisation) =>
      sql.write(
        'INSERT INTO organisations (id,name,self_register,retention_days) VALUES ($1,$2,$3,$4)',
        [row.id, row.name, row.selfRegister, row.retentionDays],
      ),
    users: () =>
      sql.rows<User>(
        'SELECT id,organisation_id AS "organisationId",email,password_hash AS "passwordHash",role,status FROM users ORDER BY id',
      ),
    addUser: (row: User) =>
      sql.write(
        'INSERT INTO users (id,organisation_id,email,password_hash,role,status) VALUES ($1,$2,$3,$4,$5,$6)',
        [
          row.id,
          row.organisationId,
          row.email,
          row.passwordHash,
          row.role,
          row.status,
        ],
      ),
    saveUser: (row: User) =>
      sql.write(
        'UPDATE users SET email=$2,password_hash=$3,role=$4,status=$5 WHERE id=$1',
        [row.id, row.email, row.passwordHash, row.role, row.status],
      ),
    devices: () =>
      sql.rows<Device>(
        'SELECT id,user_id AS "userId",enrolled_at AS "enrolledAt",last_seen_at AS "lastSeenAt",revoked FROM devices ORDER BY id',
      ),
    addDevice: (row: Device) =>
      sql.write(
        'INSERT INTO devices(id,user_id,enrolled_at,last_seen_at,revoked) VALUES ($1,$2,$3,$4,$5)',
        [row.id, row.userId, row.enrolledAt, row.lastSeenAt, row.revoked],
      ),
    saveDevice: (row: Device) =>
      sql.write('UPDATE devices SET last_seen_at=$2,revoked=$3 WHERE id=$1', [
        row.id,
        row.lastSeenAt,
        row.revoked,
      ]),
    refresh: () =>
      sql.rows<RefreshFamily>(
        'SELECT id,user_id AS "userId",device_id AS "deviceId",token_hash AS "tokenHash",rotated,revoked,expires_at AS "expiresAt" FROM refresh_families ORDER BY id',
      ),
    addRefresh: (row: RefreshFamily) =>
      sql.write(
        'INSERT INTO refresh_families(id,user_id,device_id,token_hash,rotated,revoked,expires_at) VALUES ($1,$2,$3,$4,$5,$6,$7)',
        [
          row.id,
          row.userId,
          row.deviceId,
          row.tokenHash,
          row.rotated,
          row.revoked,
          row.expiresAt,
        ],
      ),
    saveRefresh: (row: RefreshFamily) =>
      sql.write(
        'UPDATE refresh_families SET rotated=$2,revoked=$3 WHERE id=$1',
        [row.id, row.rotated, row.revoked],
      ),
    invites: () =>
      sql.rows<Invite>(
        'SELECT token_hash AS "tokenHash",user_id AS "userId",used,expires_at AS "expiresAt" FROM invitations ORDER BY token_hash',
      ),
    addInvite: (row: Invite) =>
      sql.write(
        'INSERT INTO invitations(token_hash,user_id,used,expires_at) VALUES ($1,$2,$3,$4)',
        [row.tokenHash, row.userId, row.used, row.expiresAt],
      ),
    saveInvite: (row: Invite) =>
      sql.write('UPDATE invitations SET used=$2 WHERE token_hash=$1', [
        row.tokenHash,
        row.used,
      ]),
    lockout: async (key: string) =>
      (
        await sql.rows<{ failures: number; until: string | null }>(
          'SELECT failures,locked_until AS until FROM login_lockouts WHERE key=$1',
          [key],
        )
      )[0] ?? { failures: 0, until: null },
    setLockout: (key: string, failures: number, until: string | null) =>
      sql.write(
        'INSERT INTO login_lockouts(key,failures,locked_until) VALUES ($1,$2,$3) ON CONFLICT(key) DO UPDATE SET failures=EXCLUDED.failures,locked_until=EXCLUDED.locked_until',
        [key, failures, until],
      ),
    seedRole: (email: string, role: Role) =>
      sql.write('UPDATE users SET role=$2 WHERE email=$1', [email, role]),
  };
}
