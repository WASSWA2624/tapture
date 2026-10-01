import { createHash, randomBytes, randomUUID } from 'node:crypto';
import type { AppConfig } from '../../config/schema.js';
import { normaliseEmail, sameEmail } from '../../domain/email.js';
import {
  conflict,
  forbidden,
  invalidCredentials,
  invalidRequest,
} from '../../domain/errors.js';
import type { Role } from '../../domain/permissions.js';
import { withTransaction } from '../../repositories/base.js';
import type { Repository as Store } from '../../repositories/repository.js';
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
): Promise<{
  userId: string;
}> {
  if (input.password.length < 12)
    throw invalidRequest('Use at least 12 characters.');
  const org = (await store.orgs()).find(
    (row) => row.id === input.organisationId,
  );
  if (org === undefined) throw forbidden();
  if (input.invitationToken !== undefined) {
    const hash = createHash('sha256')
      .update(input.invitationToken)
      .digest('hex');
    const passwordHash = await hashPassword(input.password, config);
    return withTransaction(store, async (tx) => {
      const invite = await tx.inviteByHash(hash);
      const user =
        invite === undefined ? undefined : await tx.userById(invite.userId);
      if (
        invite === undefined ||
        invite.used ||
        invite.purpose !== 'invitation' ||
        !(Date.parse(invite.expiresAt) > Date.now()) ||
        user === undefined ||
        user.status !== 'invited' ||
        user.organisationId !== org.id ||
        !sameEmail(user.email, input.email)
      )
        throw forbidden();
      await tx.saveUser({ ...user, passwordHash, status: 'active' });
      await tx.saveInvite({ ...invite, used: true });
      await tx.recordAudit({
        actorId: user.id,
        action: 'accept_invite',
        target: user.id,
        before: null,
        after: { status: 'active' },
      });
      return { userId: user.id };
    });
  }
  if (!org.selfRegister) throw forbidden();
  const email = normaliseEmail(input.email);
  const userId = randomUUID();
  // Hash on both the new-address and duplicate paths, so registration is not
  // an address oracle through its response or password work timing.
  const passwordHash = await hashPassword(input.password, config);
  await withTransaction(store, async (tx) => {
    if ((await tx.userByEmail(org.id, email)) !== undefined) return;
    await tx.addUser({
      id: userId,
      organisationId: org.id,
      email,
      passwordHash,
      role: 'field_operator',
      status: 'active',
    });
    await tx.recordAudit({
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
  input: {
    organisationId: string;
    email: string;
    role: Role;
    actorId: string;
  },
): Promise<{
  userId: string;
  invitationToken: string;
}> {
  const email = normaliseEmail(input.email);
  const taken =
    (await store.userByEmail(input.organisationId, email)) !== undefined;
  if (taken) throw conflict('An account with that address already exists.');
  const userId = randomUUID();
  const invitationToken = randomBytes(24).toString('base64url');
  const passwordHash = await hashPassword(
    randomBytes(16).toString('hex'),
    config,
  );
  await withTransaction(store, async (tx) => {
    await tx.addUser({
      id: userId,
      organisationId: input.organisationId,
      email,
      passwordHash,
      role: input.role,
      status: 'invited',
    });
    await tx.addInvite({
      tokenHash: createHash('sha256').update(invitationToken).digest('hex'),
      userId,
      used: false,
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      purpose: 'invitation',
    });
    await tx.recordAudit({
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
  input: {
    userId: string;
    currentPassword: string;
    nextPassword: string;
  },
): Promise<void> {
  const user = await store.userById(input.userId);
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
    const current = await tx.userById(user.id);
    if (
      current === undefined ||
      current.status !== 'active' ||
      current.passwordHash !== user.passwordHash
    )
      throw invalidCredentials();
    await tx.saveUser({ ...current, passwordHash });
    await revokeUser(tx, user.id);
    await tx.recordAudit({
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
  input: {
    email: string;
    organisationId: string;
  },
): Promise<void> {
  const email = normaliseEmail(input.email);
  // Operators fulfil the request through the private CLI. A public response
  // never contains a reset credential or reveals whether the account exists.
  await store.recordAudit({
    actorId: 'anonymous',
    action: 'password_reset_requested',
    target: input.organisationId,
    before: null,
    after: { email, outcome: 'requested' },
  });
}

export async function issuePasswordReset(
  store: Store,
  input: { email: string; organisationId: string; actorId: string },
): Promise<string> {
  const user = await store.userByEmail(input.organisationId, input.email);
  if (user === undefined || user.status !== 'active')
    throw invalidRequest('An active account is required.');
  const token = randomBytes(24).toString('base64url');
  await store.withTransaction(async (tx) => {
    await tx.addInvite({
      tokenHash: createHash('sha256').update(token).digest('hex'),
      userId: user.id,
      used: false,
      expiresAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
      purpose: 'password_reset',
    });
    await tx.recordAudit({
      actorId: input.actorId,
      action: 'issue_password_reset',
      target: user.id,
      before: null,
      after: { outcome: 'issued' },
    });
  });
  return token;
}
export async function completeReset(
  store: Store,
  config: AppConfig,
  input: {
    token: string;
    password: string;
  },
): Promise<void> {
  const hash = createHash('sha256').update(input.token).digest('hex');
  if (input.password.length < 12)
    throw invalidRequest('Use at least 12 characters.');
  const passwordHash = await hashPassword(input.password, config);
  await withTransaction(store, async (tx) => {
    const invite = await tx.inviteByHash(hash);
    if (
      invite === undefined ||
      invite.used ||
      invite.purpose !== 'password_reset' ||
      !(Date.parse(invite.expiresAt) > Date.now())
    )
      throw invalidRequest('That reset link is not valid.');
    const user = await tx.userById(invite.userId);
    if (user === undefined || user.status !== 'active')
      throw invalidRequest('That reset link is not valid.');
    await tx.saveUser({ ...user, passwordHash });
    await tx.saveInvite({ ...invite, used: true });
    await revokeUser(tx, user.id);
    await tx.recordAudit({
      actorId: user.id,
      action: 'reset_password',
      target: user.id,
      before: null,
      after: null,
    });
  });
}
