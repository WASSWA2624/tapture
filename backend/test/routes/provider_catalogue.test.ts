import assert from 'node:assert/strict';
import { it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';
import { catalogueProvider } from '../fakes/provider_catalogue.js';
import { fakeProvider } from '../../src/services/ai/provider.js';
import { readContract, responseMismatches } from '../contract/openapi.js';

it('validates configured catalogue, credentials and exact keyless billing against OpenAPI', async () => {
  const deps = makeDeps({
    AI_PROVIDER_CATALOGUE: JSON.stringify([
      catalogueProvider(),
      catalogueProvider({
        id: 'key-required',
        protocol: 'gemini-generate-content',
        authMode: 'required',
      }),
    ]),
    AI_CREDENTIAL_ENCRYPTION_KEY: 'ab'.repeat(32),
  });
  const user = await seedUser(deps, { role: 'field_operator' });
  deps.store.addProject({
    id: 'project',
    organisationId: 'org-1',
    name: 'Field',
    relayEnabled: false,
    neverRelay: true,
    retentionDays: 30,
  });
  deps.store.addMember({
    projectId: 'project',
    userId: 'user-1',
    contextScope: null,
  });
  const selected: string[] = [];
  deps.providerFactory = (provider, key) => {
    selected.push(provider);
    assert.equal(key, provider === 'field-ai' ? '' : 'private-fixture-key');
    return fakeProvider('ok');
  };
  const app = appFor(deps);
  const auth = (await signIn(app, user)).accessToken;
  const doc = await readContract();
  const catalogue = await request(app)
    .get('/api/v1/ai/providers')
    .auth(auth, { type: 'bearer' });
  assert.equal(catalogue.status, 200);
  assert.deepEqual(
    responseMismatches(doc, '/api/v1/ai/providers', 'get', 200, catalogue.body),
    [],
  );
  assert.equal(selected.length, 0);
  for (const method of ['get', 'put', 'delete'] as const) {
    const response = await request(app)
      [method]('/api/v1/ai/credentials/field-ai')
      .auth(auth, { type: 'bearer' })
      .send(method === 'put' ? { apiKey: 'unused' } : {});
    assert.equal(response.status, 400);
    assert.equal(response.body.error.code, 'invalid_request');
  }
  await request(app)
    .put('/api/v1/ai/credentials/key-required')
    .auth(auth, { type: 'bearer' })
    .send({ apiKey: 'private-fixture-key' })
    .expect(204);
  const status = await request(app)
    .get('/api/v1/ai/credentials/key-required')
    .auth(auth, { type: 'bearer' });
  assert.deepEqual(
    responseMismatches(
      doc,
      '/api/v1/ai/credentials/{provider}',
      'get',
      200,
      status.body,
    ),
    [],
  );
  for (const billing of [
    { kind: 'managed', provider: 'field-ai' },
    { kind: 'personal', provider: 'key-required' },
  ]) {
    const response = await request(app)
      .post('/api/v1/ai/extract')
      .auth(auth, { type: 'bearer' })
      .send({
        projectId: 'project',
        model: 'small',
        payload: {
          instructions: 'Evidence only',
          data: { caption: 'source' },
          media: [],
          responseMimeType: 'application/json',
        },
        billing,
      });
    assert.equal(response.status, 200);
    assert.equal(response.body.provider, billing.provider);
    assert.equal(response.body.billingKind, billing.kind);
    assert.deepEqual(
      responseMismatches(doc, '/api/v1/ai/extract', 'post', 200, response.body),
      [],
    );
  }
  assert.deepEqual(selected, ['field-ai', 'key-required']);
  await request(app).get('/api/v1/ai/providers').expect(401);
  const unknown = await request(app)
    .post('/api/v1/ai/extract')
    .auth(auth, { type: 'bearer' })
    .send({
      projectId: 'project',
      model: 'small',
      payload: {},
      billing: { kind: 'managed', provider: 'not-configured' },
    });
  assert.equal(unknown.status, 400);
  assert.equal(deps.store.usage().length, 2);
});
