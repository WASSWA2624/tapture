import assert from 'node:assert/strict';
import { it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';
import {
  catalogueProvider,
  xaiCatalogueProvider,
} from '../fakes/provider_catalogue.js';
import { fakeProvider } from '../../src/services/ai/provider.js';
import { openaiProvider } from '../../src/services/ai/openai-provider.js';
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

it('exposes xAI through the unchanged metadata and Responses contracts with permission and quota gates', async () => {
  const definition = xaiCatalogueProvider();
  const deps = makeDeps({
    AI_PROVIDER_CATALOGUE: JSON.stringify([definition]),
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
  let calls = 0;
  deps.providerFactory = (id, key) => {
    assert.equal(id, 'xai');
    assert.equal(key, 'private-xai-fixture');
    return openaiProvider(
      deps.config,
      key,
      async (url, init) => {
        calls++;
        assert.equal(url, 'https://api.x.ai/v1/responses');
        assert.equal(init?.redirect, 'error');
        assert.equal(
          (init?.headers as Record<string, string>)['Authorization'],
          'Bearer private-xai-fixture',
        );
        const body = JSON.parse(init?.body as string) as Record<
          string,
          unknown
        >;
        assert.equal(body['store'], false);
        assert.equal(body['background'], false);
        assert.equal(body['model'], 'grok-4.7');
        return new Response(
          JSON.stringify({
            model: 'grok-4.7',
            status: 'completed',
            output: [
              {
                type: 'message',
                content: [{ type: 'output_text', text: '{"fields":{}}' }],
              },
            ],
          }),
        );
      },
      definition,
    );
  };
  const app = appFor(deps);
  const auth = (await signIn(app, user)).accessToken;
  const doc = await readContract();
  const catalogue = () =>
    request(app).get('/api/v1/ai/providers').auth(auth, { type: 'bearer' });
  const before = await catalogue();
  assert.equal(calls, 0);
  await request(app)
    .put('/api/v1/ai/credentials/xai')
    .auth(auth, { type: 'bearer' })
    .send({ apiKey: 'private-xai-fixture' })
    .expect(204);
  const after = await catalogue();
  for (const response of [before, after]) {
    assert.equal(response.status, 200);
    assert.deepEqual(
      responseMismatches(
        doc,
        '/api/v1/ai/providers',
        'get',
        200,
        response.body,
      ),
      [],
    );
    const metadata = JSON.stringify(response.body);
    for (const forbidden of [
      'baseUrl',
      'api.x.ai',
      'private-xai-fixture',
      'encryptedKey',
    ])
      assert.equal(metadata.includes(forbidden), false);
  }
  const rows = after.body.providers as {
    provider: string;
    personalConfigured: boolean;
    operations: string[];
  }[];
  assert.equal(rows.filter((row) => row.provider === 'xai').length, 1);
  assert.equal(
    rows.find((row) => row.provider === 'xai')?.personalConfigured,
    true,
  );
  assert.deepEqual(rows.find((row) => row.provider === 'xai')?.operations, [
    'ocr',
    'extract',
    'refine',
  ]);
  assert.equal(calls, 0);
  const payload = {
    projectId: 'project',
    model: 'grok-4.7',
    payload: {
      instructions: 'Evidence only',
      data: { caption: 'source' },
      media: [{ mimeType: 'image/jpeg', base64: 'AQID' }],
      responseMimeType: 'application/json',
    },
    billing: { kind: 'personal', provider: 'xai' },
  };
  for (const operation of ['ocr', 'extract', 'refine']) {
    const response = await request(app)
      .post(`/api/v1/ai/${operation}`)
      .auth(auth, { type: 'bearer' })
      .send(payload);
    assert.equal(response.status, 200);
    assert.equal(response.body.provider, 'xai');
    assert.equal(response.body.model, 'grok-4.7');
    assert.deepEqual(
      responseMismatches(
        doc,
        `/api/v1/ai/${operation}`,
        'post',
        200,
        response.body,
      ),
      [],
    );
  }
  const reviewer = await seedUser(deps, {
    id: 'reviewer',
    email: 'reviewer@acme.test',
    role: 'reviewer',
  });
  const deniedAuth = (await signIn(app, reviewer)).accessToken;
  for (const [operation, body, token, status, code] of [
    ['transcribe', payload, auth, 400, 'invalid_request'],
    [
      'extract',
      { ...payload, model: 'unapproved' },
      auth,
      400,
      'invalid_request',
    ],
    ['extract', { ...payload, maxCost: 0.001 }, auth, 429, 'quota_exceeded'],
    ['extract', { ...payload, projectId: 'other' }, auth, 404, 'not_found'],
    ['extract', payload, deniedAuth, 404, 'not_found'],
  ] as const) {
    const response = await request(app)
      .post(`/api/v1/ai/${operation}`)
      .auth(token, { type: 'bearer' })
      .send(body);
    assert.equal(response.status, status);
    assert.equal(response.body.error.code, code);
  }
  deps.config.aiProjectBudget = 0;
  await request(app)
    .post('/api/v1/ai/extract')
    .auth(auth, { type: 'bearer' })
    .send(payload)
    .expect(429);
  assert.equal(calls, 3);
  assert.equal(deps.store.usage().length, 3);
});
