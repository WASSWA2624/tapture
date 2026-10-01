import { can, type Principal, type Role } from '../../domain/permissions.js';
import { forbidden, notFound } from '../../domain/errors.js';
import { withTransaction } from '../../repositories/base.js';
import type { Repository as Store } from '../../repositories/repository.js';
import type { AppConfig } from '../../config/schema.js';
import { createInvitedUser } from '../auth/account.js';
import type { User } from '../../types/index.js';
import { page } from '../pagination.js';
function visible(user: User): Omit<User, 'passwordHash'> {
  return {
    id: user.id,
    organisationId: user.organisationId,
    email: user.email,
    role: user.role,
    status: user.status,
  };
}
export async function listUsers(
  store: Store,
  principal: Principal,
  query?: {
    cursor?: string;
    limit?: number;
  },
) {
  if (!can(principal, 'manageUsers')) throw notFound();
  const limit = query?.limit ?? 50;
  const result = page(
    (
      await store.users({
        ...query,
        organisationId: principal.organisationId,
        limit: limit + 1,
      })
    ).map(visible),
    limit,
    (row) => row.id,
  );
  return { users: result.items, nextCursor: result.nextCursor };
}
export async function inviteUser(
  store: Store,
  config: AppConfig,
  principal: Principal,
  input: {
    email: string;
    role: Role;
  },
) {
  if (!can(principal, 'manageUsers')) throw notFound();
  return await createInvitedUser(store, config, {
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
  patch: {
    role?: Role;
    status?: User['status'];
  },
): Promise<void> {
  if (!can(principal, 'manageUsers')) throw notFound();
  const user = await store.userById(userId);
  if (user === undefined || user.organisationId !== principal.organisationId)
    throw notFound();
  if (patch.role === undefined && patch.status === undefined) throw forbidden();
  await withTransaction(store, async (tx) => {
    await tx.saveUser({
      ...user,
      role: patch.role ?? user.role,
      status: patch.status ?? user.status,
    });
    await tx.recordAudit({
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
