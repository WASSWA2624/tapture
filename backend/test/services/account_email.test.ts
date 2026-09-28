import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { normaliseEmail, sameEmail } from '../../src/domain/email.js';
import { AppError } from '../../src/domain/errors.js';
import {
  createInvitedUser,
  registerAccount,
  requestReset,
} from '../../src/services/auth/account.js';
import { bootstrapOrganisation } from '../../src/services/auth/bootstrap.js';
import { login } from '../../src/services/auth/login.js';
import { appFor, makeDeps } from '../helpers.js';

const isConflict = (error: unknown): boolean =>
  error instanceof AppError && error.code === 'conflict';

describe('account email', () => {
  it('trims and lower-cases an address before comparing it', () => {
    assert.equal(normaliseEmail('  Admin@Acme.Test '), 'admin@acme.test');
    assert.equal(sameEmail('Admin@Acme.Test', ' admin@acme.test'), true);
    assert.equal(sameEmail('admin@acme.test', 'other@acme.test'), false);
  });

  it('signs in the bootstrap administrator with the address in any case', async () => {
    const deps = makeDeps();
    await bootstrapOrganisation(deps.store, deps.config, {
      name: 'Acme',
      email: ' Admin@Acme.Test ',
      password: 'bootstrap-secret-value',
    });
    assert.deepEqual(
      deps.store.users().map((user) => user.email),
      ['admin@acme.test'],
    );
    const app = appFor(deps);
    for (const email of [
      'Admin@Acme.Test',
      'admin@acme.test',
      'ADMIN@ACME.TEST ',
    ]) {
      const response = await request(app).post('/api/v1/auth/login').send({
        email,
        password: 'bootstrap-secret-value',
        deviceId: 'device-admin',
      });
      assert.equal(response.status, 200, JSON.stringify(response.body));
    }
  });

  it('counts failed sign-ins against one address whatever its case', async () => {
    const deps = makeDeps();
    const identity = await bootstrapOrganisation(deps.store, deps.config, {
      name: 'Acme',
      email: 'admin@acme.test',
      password: 'bootstrap-secret-value',
    });
    for (const email of ['Admin@Acme.Test', 'admin@acme.test']) {
      await assert.rejects(
        () =>
          login(deps.store, deps.config, {
            email,
            password: 'wrong-secret-value',
            deviceId: 'device-admin',
            organisationId: identity.organisationId,
          }),
        (error: unknown) =>
          error instanceof AppError && error.code === 'invalid_credentials',
      );
    }
    const lock = deps.store.lockout(
      `addr:${identity.organisationId}:admin@acme.test`,
    );
    assert.equal(lock.failures, 2);
  });

  it('stores invited and registered addresses in one form and finds them for a reset', async () => {
    const deps = makeDeps();
    deps.store.addOrg({
      id: 'org-1',
      name: 'Acme',
      selfRegister: true,
      retentionDays: 30,
    });
    const invited = await createInvitedUser(deps.store, deps.config, {
      organisationId: 'org-1',
      email: ' Invited@Acme.Test',
      role: 'reviewer',
      actorId: 'admin',
    });
    await assert.rejects(
      () =>
        createInvitedUser(deps.store, deps.config, {
          organisationId: 'org-1',
          email: 'INVITED@acme.test',
          role: 'reviewer',
          actorId: 'admin',
        }),
      isConflict,
    );
    await registerAccount(deps.store, deps.config, {
      email: 'invited@ACME.test',
      password: 'invited-secret-value',
      organisationId: 'org-1',
      invitationToken: invited.invitationToken,
    });
    assert.equal(
      deps.store.users().find((user) => user.id === invited.userId)?.status,
      'active',
    );
    const registered = await registerAccount(deps.store, deps.config, {
      email: 'Field@Acme.Test',
      password: 'field-secret-value',
      organisationId: 'org-1',
    });
    await assert.rejects(
      () =>
        registerAccount(deps.store, deps.config, {
          email: 'field@acme.test ',
          password: 'another-secret-value',
          organisationId: 'org-1',
        }),
      isConflict,
    );
    const emails = deps.store.users().map((user) => user.email);
    assert.deepEqual(emails.sort(), ['field@acme.test', 'invited@acme.test']);
    const invites = deps.store.invites().length;
    await requestReset(deps.store, {
      email: 'FIELD@ACME.TEST',
      organisationId: 'org-1',
    });
    assert.equal(deps.store.invites().length, invites + 1);
    assert.equal(deps.store.invites().at(-1)?.userId, registered.userId);
  });
});
