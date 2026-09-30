import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';
import {
  createInvitedUser,
  issuePasswordReset,
} from '../../src/services/auth/account.js';

describe('accounts', () => {
  it('registers when enabled without revealing or replacing a duplicate account', async () => {
    const deps = makeDeps();
    deps.store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: true,
      retentionDays: 30,
    });
    const app = appFor(deps);
    const created = await request(app).post('/api/v1/auth/register').send({
      email: 'new@acme.test',
      password: 'correct-horse',
      organisationId: 'org-1',
    });
    const duplicate = await request(app).post('/api/v1/auth/register').send({
      email: 'new@acme.test',
      password: 'correct-horse',
      organisationId: 'org-1',
    });
    assert.equal(created.status, 200);
    assert.equal(duplicate.status, 200);
    assert.deepEqual(created.body, { accepted: true });
    assert.deepEqual(duplicate.body, created.body);
    assert.equal(duplicate.headers['location'], undefined);
    assert.equal(deps.store.users().length, 1);
  });

  it('does not reveal an address when registration is disabled or on reset', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps, { selfRegister: false });
    const app = appFor(deps);
    const known = await request(app).post('/api/v1/auth/register').send({
      email: account.email,
      password: 'correct-horse',
      organisationId: 'org-1',
    });
    const unknown = await request(app).post('/api/v1/auth/register').send({
      email: 'missing@acme.test',
      password: 'correct-horse',
      organisationId: 'org-1',
    });
    assert.equal(known.status, unknown.status);
    assert.deepEqual(known.body, unknown.body);
    const resetKnown = await request(app).post('/api/v1/auth/reset').send({
      email: account.email,
      organisationId: 'org-1',
    });
    const resetUnknown = await request(app).post('/api/v1/auth/reset').send({
      email: 'missing@acme.test',
      organisationId: 'org-1',
    });
    assert.deepEqual(resetKnown.body, resetUnknown.body);
  });

  it('rejects a wrong current password and an expired or replayed reset', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps);
    const app = appFor(deps);
    const tokens = await signIn(app, account);
    const wrong = await request(app)
      .post('/api/v1/auth/change-password')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({
        currentPassword: 'not-the-password',
        nextPassword: 'another-horse',
      });
    assert.equal(wrong.status, 401);
    const expired = 'expired-token';
    deps.store.addInvite({
      tokenHash: createHash('sha256').update(expired).digest('hex'),
      userId: 'user-1',
      used: false,
      purpose: 'password_reset',
      expiresAt: new Date(Date.now() - 1000).toISOString(),
    });
    const expiredResponse = await request(app).post('/api/v1/auth/reset').send({
      token: expired,
      password: 'another-horse',
    });
    assert.equal(expiredResponse.status, 400);
    const replay = 'replay-token';
    deps.store.addInvite({
      tokenHash: createHash('sha256').update(replay).digest('hex'),
      userId: 'user-1',
      used: false,
      purpose: 'password_reset',
      expiresAt: new Date(Date.now() + 60_000).toISOString(),
    });
    const first = await request(app).post('/api/v1/auth/reset').send({
      token: replay,
      password: 'another-horse',
    });
    const second = await request(app).post('/api/v1/auth/reset').send({
      token: replay,
      password: 'another-horse',
    });
    assert.equal(first.status, 200);
    assert.equal(second.status, 400);
    const refreshed = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: tokens.refreshToken });
    assert.equal(refreshed.status, 401);
  });

  it('rejects expired, cross-organisation and reset tokens on invitation acceptance', async () => {
    for (const condition of [
      'expired',
      'malformed-expiry',
      'other-organisation',
      'reset',
    ] as const) {
      const deps = makeDeps();
      await seedUser(deps);
      deps.store.addOrg({
        id: 'org-2',
        name: 'Other',
        selfRegister: false,
        retentionDays: 30,
      });
      const invited = await createInvitedUser(deps.store, deps.config, {
        organisationId: 'org-1',
        email: 'invite@example.test',
        role: 'field_operator',
        actorId: 'user-1',
      });
      const invitation = deps.store.invites()[0];
      assert.ok(invitation);
      if (condition === 'expired')
        deps.store.saveInvite({
          ...invitation,
          expiresAt: '2000-01-01T00:00:00Z',
        });
      if (condition === 'malformed-expiry')
        deps.store.saveInvite({ ...invitation, expiresAt: 'invalid' });
      if (condition === 'reset')
        deps.store.saveInvite({ ...invitation, purpose: 'password_reset' });
      const response = await request(appFor(deps))
        .post('/api/v1/auth/register')
        .send({
          email: 'invite@example.test',
          password: 'invitation-password',
          organisationId:
            condition === 'other-organisation' ? 'org-2' : 'org-1',
          invitationToken: invited.invitationToken,
        });
      assert.equal(response.status, 403, condition);
      assert.equal(
        deps.store.users().find((user) => user.id === invited.userId)?.status,
        'invited',
      );
      assert.equal(deps.store.invites()[0]?.used, false);
    }
  });

  it('consumes an invitation only once across simultaneous acceptance requests', async () => {
    const deps = makeDeps();
    await seedUser(deps);
    const invited = await createInvitedUser(deps.store, deps.config, {
      organisationId: 'org-1',
      email: 'invite@example.test',
      role: 'field_operator',
      actorId: 'user-1',
    });
    const app = appFor(deps);
    const replies = await Promise.all(
      ['first-invitation-password', 'second-invitation-password'].map(
        (password) =>
          request(app).post('/api/v1/auth/register').send({
            email: 'invite@example.test',
            password,
            organisationId: 'org-1',
            invitationToken: invited.invitationToken,
          }),
      ),
    );
    assert.deepEqual(replies.map((reply) => reply.status).sort(), [200, 403]);
    assert.equal(
      deps.store.audit().filter((event) => event.action === 'accept_invite')
        .length,
      1,
    );
  });

  it('never accepts an invitation as a password-reset capability', async () => {
    const deps = makeDeps();
    await seedUser(deps);
    const token = 'invitation-only-capability';
    deps.store.addInvite({
      tokenHash: createHash('sha256').update(token).digest('hex'),
      userId: 'user-1',
      used: false,
      purpose: 'invitation',
      expiresAt: new Date(Date.now() + 60_000).toISOString(),
    });
    const response = await request(appFor(deps))
      .post('/api/v1/auth/reset')
      .send({ token, password: 'replacement-password' });
    assert.equal(response.status, 400);
    assert.equal(deps.store.invites()[0]?.used, false);
  });

  it('completes an operator-issued reset and refuses token replay', async () => {
    const deps = makeDeps();
    const account = await seedUser(deps);
    const app = appFor(deps);
    const prior = await signIn(app, account);
    const token = await issuePasswordReset(deps.store, {
      email: account.email,
      organisationId: account.organisationId,
      actorId: 'operator@example.test',
    });
    assert.equal(JSON.stringify(deps.store.audit()).includes(token), false);
    assert.equal(
      (
        await request(app)
          .post('/api/v1/auth/reset')
          .send({ token, password: 'replacement-password' })
      ).status,
      200,
    );
    assert.equal(
      (
        await request(app)
          .post('/api/v1/auth/reset')
          .send({ token, password: 'replacement-password' })
      ).status,
      400,
    );
    assert.equal(
      (
        await request(app)
          .post('/api/v1/auth/refresh')
          .send({ refreshToken: prior.refreshToken })
      ).status,
      401,
    );
    await signIn(app, { ...account, password: 'replacement-password' });
  });
});
