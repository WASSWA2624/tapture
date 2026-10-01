import assert from 'node:assert/strict';
import { it } from 'node:test';
import request, { type Response } from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

function boundedQuery<Query extends { readonly limit?: number }, Value>(
  read: (query?: Query) => Value,
  method: string,
): (query?: Query) => Value {
  return (query) => {
    assert.ok(query !== undefined, `${method} query is scoped`);
    assert.ok(
      query.limit !== undefined && query.limit <= 101,
      `${method} query is bounded`,
    );
    return read(query);
  };
}

it('bounds every list in its repository scope and resumes after cursor rows are removed', async () => {
  const deps = makeDeps();
  const account = await seedUser(deps);
  const app = appFor(deps);
  const tokens = await signIn(app, account);
  const auth = `Bearer ${tokens.accessToken}`;
  const user = deps.store.userById('user-1');
  assert.ok(user);
  deps.store.addOrg({
    id: 'other-org',
    name: 'Other',
    selfRegister: false,
    retentionDays: 30,
  });
  deps.store.addProject({
    id: 'other-project',
    organisationId: 'other-org',
    name: 'Other',
    relayEnabled: true,
    neverRelay: false,
    retentionDays: 30,
  });
  for (let index = 0; index < 105; index += 1) {
    const suffix = index.toString().padStart(3, '0');
    deps.store.addProject({
      id: `p-${suffix}`,
      organisationId: 'org-1',
      name: 'Field',
      relayEnabled: true,
      neverRelay: false,
      retentionDays: 30,
    });
    deps.store.addUser({
      ...user,
      id: `u-${suffix}`,
      email: `${suffix}@example.test`,
      role: 'field_operator',
    });
    deps.store.addDevice({
      id: `d-${suffix}`,
      userId: user.id,
      enrolledAt: '2020-01-01T00:00:00.000Z',
      lastSeenAt: '2020-01-01T00:00:00.000Z',
      revoked: false,
    });
    deps.store.addMember({
      projectId: 'p-000',
      userId: `u-${suffix}`,
      contextScope: null,
    });
    deps.store.addPackage(
      {
        id: `r-${suffix}`,
        projectId: 'p-000',
        authorDeviceId: account.deviceId,
        byteSize: 1,
        createdAt: '2020-01-01T00:00:00.000Z',
        expiresAt: '2100-01-01T00:00:00.000Z',
        storageRef: `blob-${suffix}`,
      },
      Buffer.from([0]),
    );
    deps.store.addUsage({
      projectId: 'p-000',
      userId: user.id,
      model: 'fake',
      byteSize: 1,
      durationMs: 1,
      outcome: 'ok',
      cost: 0.01,
      at: '2020-01-01T00:00:00.000Z',
    });
  }
  deps.store.addDevice({
    id: 'foreign-device',
    userId: 'u-000',
    enrolledAt: '2020-01-01T00:00:00.000Z',
    lastSeenAt: '2020-01-01T00:00:00.000Z',
    revoked: false,
  });
  deps.store.addUsage({
    projectId: 'p-000',
    userId: 'u-000',
    model: 'fake',
    byteSize: 1,
    durationMs: 1,
    outcome: 'ok',
    cost: 0.01,
    at: '2020-01-01T00:00:00.000Z',
  });
  // Every public page must ask the persistence boundary for a bounded scope.
  deps.store.projects = boundedQuery(
    deps.store.projects.bind(deps.store),
    'projects',
  );
  deps.store.members = boundedQuery(
    deps.store.members.bind(deps.store),
    'members',
  );
  deps.store.devices = boundedQuery(
    deps.store.devices.bind(deps.store),
    'devices',
  );
  deps.store.users = boundedQuery(deps.store.users.bind(deps.store), 'users');
  deps.store.packages = boundedQuery(
    deps.store.packages.bind(deps.store),
    'packages',
  );
  const endpoints = [
    { path: '/api/v1/projects', key: 'items', id: 'id', count: 105 },
    {
      path: '/api/v1/projects/p-000/members',
      key: 'items',
      id: 'userId',
      count: 105,
    },
    { path: '/api/v1/devices', key: 'items', id: 'id', count: 106 },
    { path: '/api/v1/org/users', key: 'users', id: 'id', count: 106 },
    {
      path: '/api/v1/projects/p-000/relay/packages',
      key: 'items',
      id: 'id',
      count: 105,
    },
    {
      path: '/api/v1/ai/usage?project=p-000&from=2019-01-01&to=2021-01-01',
      key: 'items',
      id: 'id',
      count: 105,
    },
  ];
  for (const endpoint of endpoints) {
    const received: string[] = [];
    let cursor: string | null = null;
    do {
      const response: Response = await request(app)
        .get(endpoint.path)
        .query(cursor === null ? {} : { cursor })
        .set('authorization', auth);
      assert.equal(
        response.status,
        200,
        `${endpoint.path}: ${JSON.stringify(response.body)}`,
      );
      const body = response.body as Record<string, unknown>;
      const rows = body[endpoint.key] as Array<Record<string, string>>;
      assert.ok(rows.length <= 50);
      received.push(...rows.map((row) => row[endpoint.id] ?? ''));
      cursor = body['nextCursor'] as string | null;
      if (received.length === 50 && endpoint.path.endsWith('/members'))
        deps.store.removeMember('p-000', rows.at(-1)?.['userId'] ?? '');
      if (received.length === 50 && endpoint.path.endsWith('/relay/packages'))
        deps.store.removePackage(rows.at(-1)?.['id'] ?? '');
    } while (cursor !== null);
    assert.equal(received.length, endpoint.count, endpoint.path);
    assert.equal(new Set(received).size, endpoint.count, endpoint.path);
    assert.ok(
      received.every(
        (id) => !id.startsWith('other-') && id !== 'foreign-device',
      ),
    );
    const badLimit = await request(app)
      .get(endpoint.path)
      .query({ limit: '101' })
      .set('authorization', auth);
    assert.equal(badLimit.status, 400, endpoint.path);
  }
  const malformed = await request(app)
    .get('/api/v1/projects/p-000/relay/packages')
    .query({ cursor: 'malformed' })
    .set('authorization', auth);
  assert.equal(malformed.status, 400);
});
