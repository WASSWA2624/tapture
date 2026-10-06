import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { parseConfig } from '../../src/config/schema.js';
import { appFor, makeDeps } from '../helpers.js';

const origin = 'https://app.example.com';

describe('cors', () => {
  it('answers an allowed preflight before authentication and rate limiting', async () => {
    const app = appFor(
      makeDeps({
        CORS_ORIGINS: `${origin}, http://localhost:5000`,
        RATE_LIMIT_GENERAL: '1',
      }),
    );
    for (let attempt = 0; attempt < 3; attempt += 1) {
      const response = await request(app)
        .options('/api/v1/auth/me')
        .set('origin', origin)
        .set('access-control-request-method', 'GET')
        .set('access-control-request-headers', 'authorization,x-api-version');
      assert.equal(response.status, 204);
      assert.equal(response.headers['access-control-allow-origin'], origin);
      assert.equal(
        response.headers['access-control-allow-methods'],
        'GET, POST, PUT, PATCH, DELETE',
      );
      assert.equal(
        response.headers['access-control-allow-headers'],
        'Authorization, Content-Type, X-Api-Version, Idempotency-Key',
      );
      assert.equal(response.headers['access-control-max-age'], '600');
      assert.equal(
        response.headers['access-control-allow-credentials'],
        undefined,
      );
      assert.match(String(response.headers['vary']), /Origin/);
    }
  });

  it('refuses a preflight from an unlisted origin', async () => {
    const app = appFor(makeDeps({ CORS_ORIGINS: origin }));
    const response = await request(app)
      .options('/api/v1/auth/login')
      .set('origin', 'https://other.example.com')
      .set('access-control-request-method', 'POST');
    assert.equal(response.status, 403);
    assert.equal(response.headers['access-control-allow-origin'], undefined);
    assert.equal(response.headers['access-control-allow-methods'], undefined);
    assert.match(String(response.headers['vary']), /Origin/);
  });

  it('labels responses, including errors, for a listed origin only', async () => {
    const app = appFor(makeDeps({ CORS_ORIGINS: origin }));
    const listed = await request(app)
      .get('/api/v1/auth/me')
      .set('origin', origin);
    assert.equal(listed.status, 401);
    assert.equal(listed.headers['access-control-allow-origin'], origin);
    assert.equal(
      listed.headers['access-control-expose-headers'],
      'Retry-After, X-Request-Id',
    );
    const unlisted = await request(app)
      .get('/health')
      .set('origin', 'https://other.example.com');
    assert.equal(unlisted.status, 200);
    assert.equal(unlisted.headers['access-control-allow-origin'], undefined);
    assert.match(String(unlisted.headers['vary']), /Origin/);
  });

  it('sends no CORS headers when no origin is configured', async () => {
    const app = appFor(makeDeps());
    const preflight = await request(app)
      .options('/api/v1/auth/me')
      .set('origin', origin)
      .set('access-control-request-method', 'GET');
    assert.equal(preflight.headers['access-control-allow-origin'], undefined);
    assert.equal(preflight.headers['access-control-allow-methods'], undefined);
    const response = await request(app).get('/health').set('origin', origin);
    assert.equal(response.status, 200);
    assert.equal(response.headers['access-control-allow-origin'], undefined);
    assert.equal(response.headers['vary'], undefined);
  });

  it('accepts exact origins and refuses anything else at boot', () => {
    const base = { DATABASE_URL: 'memory://test', TOKEN_SECRET: 'secret' };
    assert.deepEqual(parseConfig(base).corsOrigins, []);
    assert.deepEqual(
      parseConfig({
        ...base,
        CORS_ORIGINS: 'https://App.Example.com/, http://localhost:5000,',
      }).corsOrigins,
      ['https://app.example.com', 'http://localhost:5000'],
    );
    for (const value of [
      '*',
      'null',
      'app.example.com',
      'ftp://app.example.com',
      'https://app.example.com/path',
    ]) {
      assert.throws(
        () => parseConfig({ ...base, CORS_ORIGINS: value }),
        /CORS_ORIGINS/,
      );
    }
  });
});
