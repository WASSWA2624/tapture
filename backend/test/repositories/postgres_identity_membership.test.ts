import assert from 'node:assert/strict';
import { it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import { can, type Principal } from '../../src/domain/permissions.js';
import {
  addMember,
  listMembers,
  listProjects,
  visibleProject,
} from '../../src/services/projects.js';
import { postgresConfigured, withPostgres } from '../postgres_fixture.js';

function notFound(error: unknown): boolean {
  return (
    error instanceof AppError &&
    error.code === 'not_found' &&
    error.status === 404
  );
}

function conflict(error: unknown): boolean {
  return (
    error instanceof AppError &&
    error.code === 'conflict' &&
    error.status === 409 &&
    error.publicMessage === 'That entry already exists.' &&
    error.details === undefined
  );
}

it(
  'PostgreSQL identity lookups enforce organisation email uniqueness and global device uniqueness',
  { skip: !postgresConfigured },
  async () =>
    withPostgres(async ({ store }) => {
      for (const id of ['local', 'foreign']) {
        await store.addOrg({
          id,
          name: id,
          selfRegister: false,
          retentionDays: 30,
        });
        await store.addUser({
          id: `${id}-user`,
          organisationId: id,
          email: 'shared@example.test',
          passwordHash: `${id}-irreversible-hash`,
          role: 'reviewer',
          status: 'active',
        });
      }
      assert.equal(
        (await store.userByEmail('local', ' SHARED@example.test '))?.id,
        'local-user',
      );
      assert.equal(
        (await store.userByEmail('foreign', 'shared@example.test'))?.id,
        'foreign-user',
      );
      assert.equal(
        await store.userByEmail('absent', 'shared@example.test'),
        undefined,
      );
      assert.equal(
        (await store.userById('local-user'))?.organisationId,
        'local',
      );
      assert.deepEqual(
        (await store.users({ organisationId: 'local' })).map((row) => row.id),
        ['local-user'],
      );
      await assert.rejects(
        async () =>
          store.addUser({
            id: 'duplicate-user',
            organisationId: 'local',
            email: 'shared@example.test',
            passwordHash: 'another-irreversible-hash',
            role: 'reviewer',
            status: 'active',
          }),
        conflict,
      );
      assert.equal(await store.userById('duplicate-user'), undefined);

      const now = new Date().toISOString();
      await store.addDevice({
        id: 'shared-device',
        userId: 'local-user',
        enrolledAt: now,
        lastSeenAt: now,
        revoked: false,
      });
      await store.addDevice({
        id: 'foreign-device',
        userId: 'foreign-user',
        enrolledAt: now,
        lastSeenAt: now,
        revoked: false,
      });
      await assert.rejects(
        async () =>
          store.addDevice({
            id: 'shared-device',
            userId: 'foreign-user',
            enrolledAt: now,
            lastSeenAt: now,
            revoked: false,
          }),
        conflict,
      );
      assert.equal(
        (await store.deviceById('shared-device'))?.userId,
        'local-user',
      );
      assert.deepEqual(
        (await store.devices({ userId: 'local-user' })).map((row) => row.id),
        ['shared-device'],
      );
      assert.deepEqual(
        (await store.devices({ userId: 'foreign-user' })).map((row) => row.id),
        ['foreign-device'],
      );
    }),
);

it(
  'PostgreSQL memberships round-trip scoped and unscoped grants and hide cross-organisation projects and users',
  { skip: !postgresConfigured },
  async () =>
    withPostgres(async ({ store }) => {
      for (const id of ['local', 'foreign']) {
        await store.addOrg({
          id,
          name: id,
          selfRegister: false,
          retentionDays: 30,
        });
        await store.addUser({
          id: `${id}-user`,
          organisationId: id,
          email: `${id}@example.test`,
          passwordHash: 'irreversible-hash',
          role: 'reviewer',
          status: 'active',
        });
      }
      for (const [id, organisationId] of [
        ['local-free', 'local'],
        ['local-north', 'local'],
        ['local-hidden', 'local'],
        ['foreign-project', 'foreign'],
      ]) {
        assert.ok(id && organisationId);
        await store.addProject({
          id,
          organisationId,
          name: id,
          relayEnabled: false,
          neverRelay: false,
          retentionDays: 30,
        });
      }
      await store.addMember({
        projectId: 'local-free',
        userId: 'local-user',
        contextScope: null,
      });
      await store.addMember({
        projectId: 'local-north',
        userId: 'local-user',
        contextScope: 'north',
      });
      await store.addMember({
        projectId: 'foreign-project',
        userId: 'foreign-user',
        contextScope: 'foreign-scope',
      });
      const reviewer: Principal = {
        userId: 'local-user',
        organisationId: 'local',
        role: 'reviewer',
        deviceId: 'local-device',
        contextScope: null,
      };
      const grants = await store.members({ userId: reviewer.userId });
      assert.deepEqual(
        grants.map((row) => [row.projectId, row.contextScope]),
        [
          ['local-free', null],
          ['local-north', 'north'],
        ],
      );
      const scoped = grants.find((row) => row.projectId === 'local-north');
      assert.ok(scoped);
      assert.equal(
        can({ ...reviewer, contextScope: scoped.contextScope }, 'review', {
          contextId: 'north',
        }),
        true,
      );
      assert.equal(
        can({ ...reviewer, contextScope: scoped.contextScope }, 'review', {
          contextId: 'south',
        }),
        false,
      );
      assert.equal(can(reviewer, 'review', { contextId: 'south' }), true);
      assert.deepEqual(
        (await listProjects(store, reviewer)).items.map((row) => row.id),
        ['local-free', 'local-north'],
      );
      assert.equal(
        (await visibleProject(store, reviewer, 'local-north')).id,
        'local-north',
      );
      assert.deepEqual(
        (await listMembers(store, reviewer, 'local-north')).items,
        [scoped],
      );
      await assert.rejects(
        () => visibleProject(store, reviewer, 'local-hidden'),
        notFound,
      );
      await assert.rejects(
        () => visibleProject(store, reviewer, 'foreign-project'),
        notFound,
      );
      await assert.rejects(
        () => listMembers(store, reviewer, 'foreign-project'),
        notFound,
      );
      const administrator: Principal = { ...reviewer, role: 'administrator' };
      await assert.rejects(
        () => visibleProject(store, administrator, 'foreign-project'),
        notFound,
      );
      await assert.rejects(
        () =>
          addMember(store, administrator, 'local-north', {
            userId: 'foreign-user',
            contextScope: null,
          }),
        notFound,
      );
      assert.deepEqual(await store.members({ projectId: 'local-north' }), [
        scoped,
      ]);
      await store.removeMember('local-north', 'local-user');
      await assert.rejects(
        () => visibleProject(store, reviewer, 'local-north'),
        notFound,
      );
      assert.deepEqual(
        (await listProjects(store, reviewer)).items.map((row) => row.id),
        ['local-free'],
      );
      assert.deepEqual(await store.members({ projectId: 'foreign-project' }), [
        {
          projectId: 'foreign-project',
          userId: 'foreign-user',
          contextScope: 'foreign-scope',
        },
      ]);
    }),
);
