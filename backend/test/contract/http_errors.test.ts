import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser } from '../helpers.js';
import {
  readContract,
  responseMismatches,
  schemaMismatches,
} from './openapi.js';

describe('HTTP contract errors', () => {
  it('rejects undocumented fields and invalid types with the documented error envelope', async () => {
    const doc = await readContract();
    const deps = makeDeps();
    const account = await seedUser(deps);
    const app = appFor(deps);
    const signedIn = await request(app)
      .post('/api/v1/auth/login')
      .send(account);
    const auth = `Bearer ${(signedIn.body as { accessToken: string }).accessToken}`;
    const cases: Array<{
      method: 'post' | 'patch';
      path: string;
      documentPath?: string;
      body: unknown;
    }> = [
      {
        method: 'post',
        path: '/api/v1/auth/login',
        body: { ...account, organisationId: 3 },
      },
      {
        method: 'post',
        path: '/api/v1/auth/login',
        body: { ...account, caption: 'private' },
      },
      {
        method: 'post',
        path: '/api/v1/auth/register',
        body: {
          email: account.email,
          password: account.password,
          organisationId: account.organisationId,
          caption: 'private',
        },
      },
      {
        method: 'post',
        path: '/api/v1/auth/reset',
        body: {
          email: account.email,
          organisationId: account.organisationId,
          caption: 'private',
        },
      },
      {
        method: 'post',
        path: '/api/v1/auth/logout',
        body: { refreshToken: 'absent', caption: 'private' },
      },
      {
        method: 'post',
        path: '/api/v1/auth/refresh',
        body: { refreshToken: 'absent', caption: 'private' },
      },
      {
        method: 'post',
        path: '/api/v1/auth/change-password',
        body: {
          currentPassword: account.password,
          nextPassword: account.password,
          caption: 'private',
        },
      },
      {
        method: 'post',
        path: '/api/v1/projects',
        body: { id: 'project', name: 'Metadata', caption: 'private' },
      },
      {
        method: 'patch',
        path: '/api/v1/projects/project',
        documentPath: '/api/v1/projects/{id}',
        body: { relayEnabled: 'true' },
      },
      {
        method: 'post',
        path: '/api/v1/org/users',
        body: { email: 'b@example.test', role: 'reviewer', caption: 'private' },
      },
      {
        method: 'patch',
        path: '/api/v1/org/users/user',
        documentPath: '/api/v1/org/users/{id}',
        body: { status: 3 },
      },
      {
        method: 'post',
        path: '/api/v1/relay/ack',
        body: { packageIds: ['id'], caption: 'private' },
      },
      {
        method: 'post',
        path: '/api/v1/ai/extract',
        body: {
          projectId: 'project',
          model: 'default',
          payload: {},
          caption: 'private',
        },
      },
    ];
    for (const item of cases) {
      const response = await request(app)
        [item.method](item.path)
        .set('authorization', auth)
        .send(item.body as object);
      assert.equal(response.status, 400, item.path);
      assert.deepEqual(
        responseMismatches(
          doc,
          item.documentPath ?? item.path,
          item.method,
          response.status,
          response.body,
        ),
        [],
        item.path,
      );
      assert.equal(JSON.stringify(response.body).includes('private'), false);
    }
    assert.equal(deps.store.projects().length, 0);
    assert.equal(deps.store.usage().length, 0);
  });
  it('asserts documented authentication and malformed-input error envelopes over HTTP', async () => {
    const doc = await readContract();
    const deps = makeDeps();
    const account = await seedUser(deps);
    const app = appFor(deps);
    for (const [path, methods] of Object.entries(doc.paths)) {
      if (
        !path.startsWith('/api/v1/') ||
        [
          '/api/v1/auth/login',
          '/api/v1/auth/logout',
          '/api/v1/auth/refresh',
          '/api/v1/auth/register',
          '/api/v1/auth/reset',
        ].includes(path)
      )
        continue;
      for (const method of Object.keys(methods) as Array<
        'get' | 'post' | 'patch' | 'delete'
      >) {
        const response = await request(app)[method](
          path.replace(/\{[^}]+\}/g, 'absent'),
        );
        assert.equal(response.status, 401, `${method} ${path}`);
        assert.deepEqual(
          responseMismatches(doc, path, method, response.status, response.body),
          [],
        );
        assert.equal(
          (response.body as { error: { code: string } }).error.code,
          'unauthorized',
        );
      }
    }
    const signedIn = await request(app)
      .post('/api/v1/auth/login')
      .send(account);
    const auth = `Bearer ${(signedIn.body as { accessToken: string }).accessToken}`;
    for (const path of [
      '/api/v1/projects',
      '/api/v1/org/users',
      '/api/v1/relay/ack',
      '/api/v1/ai/extract',
    ]) {
      const response = await request(app)
        .post(path)
        .set('authorization', auth)
        .set('content-type', 'application/json')
        .send('{ malformed');
      assert.equal(response.status, 400, path);
      assert.deepEqual(
        responseMismatches(doc, path, 'post', response.status, response.body),
        [],
      );
      assert.equal(
        (response.body as { error: { code: string } }).error.code,
        'invalid_request',
      );
    }
    const loginSchema =
      doc.paths['/api/v1/auth/login']?.['post']?.requestBody?.content[
        'application/json'
      ]?.schema;
    assert.ok(loginSchema);
    assert.deepEqual(
      schemaMismatches(doc, loginSchema, { email: 3, password: 'x' }),
      ['body.deviceId', 'body.email'],
    );
  });
});
