import { createHash, randomBytes, randomUUID } from 'node:crypto';
import type { AppConfig } from '../../config/schema.js';
import {
  conflict,
  forbidden,
  invalidCredentials,
  invalidRequest,
} from '../../domain/errors.js';
import type { Role } from '../../domain/permissions.js';
import { withTransaction } from '../../repositories/base.js';
import type { Store } from '../../repositories/store.js';
import { hashPassword, verifyPassword } from './password.js';
import { revokeUser } from './tokens.js';

export async function registerAccount(
  store: Store,
  config: AppConfig,
  input: {
    email: string;
    password: string;
    organisationId: string;
    invitationToken?: string;
  },
): Promise<{ userId: string }> {
  const org = store.orgs().find((row) => row.id === input.organisationId);
  if (org === undefined) throw forbidden();
  if (input.invitationToken !== undefined) {
    const hash = createHash('sha256')
      .update(input.invitationToken)
      .digest('hex');
    const invite = store
      .invites()
      .find((row) => row.tokenHash === hash && !row.used);
    const user = store.users().find((row) => row.id === invite?.userId);
    if (
      invite === undefined ||
      user === undefined ||
      user.email !== input.email
    ) {
      throw forbidden();
    }
    const passwordHash = await hashPassword(input.password, config);
    await withTransaction(store, async (tx) => {
      tx.saveUser({ ...user, passwordHash, status: 'active' });
      invite.used = true;
      tx.recordAudit({
        actorId: user.id,
        action: 'accept_invite',
        target: user.id,
        before: null,
        after: { status: 'active' },
      });
    });
    return { userId: user.id };
  }
  if (!org.selfRegister) throw forbidden();
  const taken = store
    .users()
    .some((row) => row.organisationId === org.id && row.email === input.email);
  if (taken) throw conflict('An account with that address already exists.');
  const userId = randomUUID();
  const passwordHash = await hashPassword(input.password, config);
  await withTransaction(store, async (tx) => {
    tx.addUser({
      id: userId,
      organisationId: org.id,
      email: input.email,
      passwordHash,
      role: 'field_operator',
      status: 'active',
    });
    tx.recordAudit({
      actorId: userId,
      action: 'register',
      target: userId,
      before: null,
      after: { role: 'field_operator' },
    });
  });
  return { userId };
}

export async function createInvitedUser(
  store: Store,
  config: AppConfig,
  input: { organisationId: string; email: string; role: Role; actorId: string },
): Promise<{ userId: string; invitationToken: string }> {
  const taken = store
    .users()
    .some(
      (row) =>
        row.organisationId === input.organisationId &&
        row.email === input.email,
    );
  if (taken) throw conflict('An account with that address already exists.');
  const userId = randomUUID();
  const invitationToken = randomBytes(24).toString('base64url');
  const passwordHash = await hashPassword(
    randomBytes(16).toString('hex'),
    config,
  );
  await withTransaction(store, async (tx) => {
    tx.addUser({
      id: userId,
      organisationId: input.organisationId,
      email: input.email,
      passwordHash,
      role: input.role,
      status: 'invited',
    });
    tx.addInvite({
      tokenHash: createHash('sha256').update(invitationToken).digest('hex'),
      userId,
      used: false,
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    });
    tx.recordAudit({
      actorId: input.actorId,
      action: 'invite_user',
      target: userId,
      before: null,
      after: { role: input.role, status: 'invited' },
    });
  });
  return { userId, invitationToken };
}

export async function changePassword(
  store: Store,
  config: AppConfig,
  input: { userId: string; currentPassword: string; nextPassword: string },
): Promise<void> {
  const user = store.users().find((row) => row.id === input.userId);
  if (user === undefined) throw invalidCredentials();
  const ok = await verifyPassword(
    input.currentPassword,
    user.passwordHash,
    config,
  );
  if (!ok) throw invalidCredentials();
  if (input.nextPassword.length < 12) {
    throw invalidRequest('Use at least 12 characters.');
  }
  const passwordHash = await hashPassword(input.nextPassword, config);
  await withTransaction(store, async (tx) => {
    tx.saveUser({ ...user, passwordHash });
    revokeUser(tx, user.id);
    tx.recordAudit({
      actorId: user.id,
      action: 'change_password',
      target: user.id,
      before: null,
      after: null,
    });
  });
}

export async function requestReset(
  store: Store,
  input: { email: string; organisationId: string },
): Promise<void> {
  const user = store
    .users()
    .find(
      (row) =>
        row.organisationId === input.organisationId &&
        row.email === input.email,
    );
  if (user === undefined) return;
  const token = randomBytes(24).toString('base64url');
  store.addInvite({
    tokenHash: createHash('sha256').update(token).digest('hex'),
    userId: user.id,
    used: false,
    expiresAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
  });
}

export async function completeReset(
  store: Store,
  config: AppConfig,
  input: { token: string; password: string },
): Promise<void> {
  const hash = createHash('sha256').update(input.token).digest('hex');
  const invite = store.invites().find((row) => row.tokenHash === hash);
  if (
    invite === undefined ||
    invite.used ||
    Date.parse(invite.expiresAt) <= Date.now()
  ) {
    throw invalidRequest('That reset link is not valid.');
  }
  if (input.password.length < 12)
    throw invalidRequest('Use at least 12 characters.');
  const user = store.users().find((row) => row.id === invite.userId);
  if (user === undefined) throw invalidRequest('That reset link is not valid.');
  const passwordHash = await hashPassword(input.password, config);
  await withTransaction(store, async (tx) => {
    tx.saveUser({ ...user, passwordHash, status: 'active' });
    invite.used = true;
    revokeUser(tx, user.id);
    tx.recordAudit({
      actorId: user.id,
      action: 'reset_password',
      target: user.id,
      before: null,
      after: null,
    });
  });
}
