import { can, type Principal, type Role } from '../../domain/permissions.js';
import { forbidden, notFound } from '../../domain/errors.js';
import { withTransaction } from '../../repositories/base.js';
import type { Store } from '../../repositories/store.js';
import type { AppConfig } from '../../config/schema.js';
import { createInvitedUser } from '../auth/account.js';
import type { User } from '../../types/index.js';

function visible(user: User): Omit<User, 'passwordHash'> {
  return {
    id: user.id,
    organisationId: user.organisationId,
    email: user.email,
    role: user.role,
    status: user.status,
  };
}

export function listUsers(
  store: Store,
  principal: Principal,
  query?: { cursor?: string; limit?: number },
) {
  if (!can(principal, 'manageUsers')) throw notFound();
  const rows = store
    .users()
    .filter((row) => row.organisationId === principal.organisationId)
    .map(visible);
  const limit = query?.limit ?? 50;
  const start =
    query?.cursor === undefined
      ? 0
      : rows.findIndex((row) => row.id === query.cursor) + 1;
  const users = rows.slice(start, start + limit);
  const last = users.at(-1);
  const hasMore = start + users.length < rows.length;
  return { users, nextCursor: hasMore ? (last?.id ?? null) : null };
}

export async function inviteUser(
  store: Store,
  config: AppConfig,
  principal: Principal,
  input: { email: string; role: Role },
) {
  if (!can(principal, 'manageUsers')) throw notFound();
  return createInvitedUser(store, config, {
    organisationId: principal.organisationId,
    email: input.email,
    role: input.role,
    actorId: principal.userId,
  });
}

export async function patchUser(
  store: Store,
  principal: Principal,
  userId: string,
  patch: { role?: Role; status?: User['status'] },
): Promise<void> {
  if (!can(principal, 'manageUsers')) throw notFound();
  const user = store
    .users()
    .find(
      (row) =>
        row.id === userId && row.organisationId === principal.organisationId,
    );
  if (user === undefined) throw notFound();
  if (patch.role === undefined && patch.status === undefined) throw forbidden();
  await withTransaction(store, async (tx) => {
    tx.saveUser({
      ...user,
      role: patch.role ?? user.role,
      status: patch.status ?? user.status,
    });
    tx.recordAudit({
      actorId: principal.userId,
      action: 'change_role',
      target: userId,
      before: { role: user.role, status: user.status },
      after: {
        role: patch.role ?? user.role,
        status: patch.status ?? user.status,
      },
    });
  });
}
