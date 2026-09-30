import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import type { Express } from 'express';
import request from 'supertest';
import { appFor, makeDeps, seedUser } from '../helpers.js';
import { compareContract, type HttpOperation } from './compare.js';
import { driftedApp } from './fixtures/drifted_route.js';
import {
  readContract,
  responseMismatches,
  schemaMismatches,
} from './openapi.js';

function liveOperations(app: Express): HttpOperation[] {
  const stack = (
    app as unknown as {
      _router: {
        stack: Array<{
          route?: { path: string; methods: Record<string, boolean> };
        }>;
      };
    }
  )._router.stack;
  return stack.flatMap((layer) =>
    layer.route === undefined
      ? []
      : Object.keys(layer.route.methods).map((method) => ({
          path: normalise(layer.route?.path ?? ''),
          method,
        })),
  );
}

function normalise(routePath: string): string {
  return routePath.replace(/:([A-Za-z]+)/g, '{$1}');
}

describe('contract', () => {
  it('compares HTTP methods in both directions and rejects real response drift', async () => {
    const doc = await readContract();
    const documented = Object.entries(doc.paths).flatMap(([path, methods]) =>
      Object.keys(methods).map((method) => ({ path, method })),
    );
    assert.deepEqual(
      compareContract(documented, liveOperations(appFor(makeDeps()))),
      [],
    );
    const drift = driftedApp();
    const methodMismatches = compareContract(
      [{ path: '/health', method: 'get' }],
      liveOperations(drift),
    );
    assert.deepEqual(methodMismatches, [{ path: '/health', field: 'post' }]);
    const response = await request(drift).get('/health');
    assert.deepEqual(
      responseMismatches(doc, '/health', 'get', response.status, response.body),
      [
        'get /health: body.status.enum',
        'get /health: body.status',
        'get /health: body.recordText',
      ],
    );
  });

  it('checks every documented operation against real HTTP response and payload schemas', async () => {
    const doc = await readContract();
    const deps = makeDeps();
    const account = await seedUser(deps);
    const app = appFor(deps);
    const checked = new Set<string>();
    let token = '';
    const run = async (
      method: 'get' | 'post' | 'patch' | 'delete',
      url: string,
      path = url,
      body?: unknown,
      status = 200,
      key?: string,
    ) => {
      const operation = doc.paths[path]?.[method];
      assert.ok(operation, `${method} ${path} is documented`);
      const schema = operation.requestBody?.content['application/json']?.schema;
      if (schema !== undefined)
        assert.deepEqual(
          schemaMismatches(doc, schema, body),
          [],
          `${method} ${path} request`,
        );
      let call = request(app)[method](url);
      if (token) call = call.set('authorization', `Bearer ${token}`);
      if (key) call = call.set('idempotency-key', key);
      if (Buffer.isBuffer(body))
        call = call.set('content-type', 'application/octet-stream').send(body);
      else if (body !== undefined)
        call = call.send(body as Record<string, unknown>);
      const response = await call;
      assert.equal(
        response.status,
        status,
        `${method} ${path}: ${JSON.stringify(response.body)}`,
      );
      assert.deepEqual(
        responseMismatches(doc, path, method, response.status, response.body),
        [],
        `${method} ${path} response`,
      );
      assert.ok(response.headers['x-request-id']);
      if (status === 201) assert.ok(response.headers['location']);
      checked.add(`${method} ${path}`);
      return response;
    };
    await run('get', '/health');
    await run('get', '/ready');
    await run('get', '/version');
    const signedIn = await run(
      'post',
      '/api/v1/auth/login',
      undefined,
      account,
    );
    const pair = signedIn.body as { accessToken: string; refreshToken: string };
    token = pair.accessToken;
    const refreshed = await run('post', '/api/v1/auth/refresh', undefined, {
      refreshToken: pair.refreshToken,
    });
    const refreshedPair = refreshed.body as {
      accessToken: string;
      refreshToken: string;
    };
    token = refreshedPair.accessToken;
    await run('post', '/api/v1/auth/register', undefined, {
      email: account.email,
      password: account.password,
      organisationId: 'org-1',
    });
    await run('post', '/api/v1/auth/reset', undefined, {
      email: account.email,
      organisationId: 'org-1',
    });
    await run('get', '/api/v1/auth/me');
    await run('get', '/api/v1/devices');
    await run('post', '/api/v1/devices', undefined, undefined, 201);
    await run('get', '/api/v1/org/users');
    const invited = await run(
      'post',
      '/api/v1/org/users',
      undefined,
      { email: 'invited@example.test', role: 'reviewer' },
      201,
    );
    const invitedId = (invited.body as { userId: string }).userId;
    await run(
      'patch',
      `/api/v1/org/users/${invitedId}`,
      '/api/v1/org/users/{id}',
      { role: 'field_operator' },
      204,
    );
    await run(
      'post',
      '/api/v1/projects',
      undefined,
      { id: 'contract-project', name: 'Field' },
      201,
    );
    await run('get', '/api/v1/projects');
    await run(
      'patch',
      '/api/v1/projects/contract-project',
      '/api/v1/projects/{id}',
      { relayEnabled: true },
    );
    await run(
      'get',
      '/api/v1/projects/contract-project/members',
      '/api/v1/projects/{id}/members',
    );
    await run(
      'post',
      '/api/v1/projects/contract-project/members',
      '/api/v1/projects/{id}/members',
      { userId: invitedId },
      201,
    );
    await run(
      'delete',
      `/api/v1/projects/contract-project/members/${invitedId}`,
      '/api/v1/projects/{id}/members/{userId}',
      undefined,
      204,
    );
    const bytes = Buffer.from([0, 255, 11, 0]);
    const pushed = await run(
      'post',
      '/api/v1/projects/contract-project/relay/packages',
      '/api/v1/projects/{id}/relay/packages',
      bytes,
      201,
      'contract-push',
    );
    const packageId = (pushed.body as { id: string }).id;
    await run(
      'get',
      '/api/v1/projects/contract-project/relay/packages',
      '/api/v1/projects/{id}/relay/packages',
    );
    const fetched = await run(
      'get',
      `/api/v1/projects/contract-project/relay/packages/${packageId}`,
      '/api/v1/projects/{id}/relay/packages/{packageId}',
    );
    assert.deepEqual(fetched.body, bytes);
    await run(
      'get',
      '/api/v1/projects/contract-project/relay/state',
      '/api/v1/projects/{id}/relay/state',
    );
    await run(
      'post',
      '/api/v1/relay/ack',
      undefined,
      { packageIds: [packageId] },
      200,
      'contract-ack',
    );
    for (const method of ['extract', 'ocr', 'transcribe', 'refine'])
      await run('post', `/api/v1/ai/${method}`, undefined, {
        projectId: 'contract-project',
        model: 'fake',
        payload: {
          instructions: 'Device instructions',
          data: {},
          media: [],
          responseMimeType: 'text/plain',
        },
      });
    await run(
      'get',
      '/api/v1/ai/usage?project=contract-project&from=2000-01-01&to=2999-01-01',
      '/api/v1/ai/usage',
    );
    await run(
      'post',
      '/api/v1/auth/change-password',
      undefined,
      { currentPassword: account.password, nextPassword: 'new-password-value' },
      204,
    );
    await run(
      'post',
      '/api/v1/auth/logout',
      undefined,
      { refreshToken: refreshedPair.refreshToken },
      204,
    );
    await run(
      'delete',
      `/api/v1/devices/${account.deviceId}`,
      '/api/v1/devices/{id}',
      undefined,
      204,
    );
    await run('get', '/metrics');
    const documented = Object.entries(doc.paths).flatMap(([path, methods]) =>
      Object.keys(methods).map((method) => `${method} ${path}`),
    );
    assert.deepEqual([...checked].sort(), documented.sort());
  });
});
