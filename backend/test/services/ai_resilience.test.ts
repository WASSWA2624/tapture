import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import { fakeProvider } from '../../src/services/ai/provider.js';
import {
  callProvider,
  resetBreakers,
} from '../../src/services/ai/resilience.js';
import { testConfig } from '../helpers.js';

describe('ai resilience', () => {
  it('retries a failure and opens the breaker', async () => {
    resetBreakers();
    const config = testConfig({
      AI_RETRY_LIMIT: '1',
      AI_BREAKER_THRESHOLD: '1',
      AI_TIMEOUT_MS: '50',
    });
    const request = {
      projectId: 'project-1',
      model: 'fake-fail',
      payload: Buffer.from('hi'),
    };
    await assert.rejects(
      () => callProvider(fakeProvider('fail'), 'extract', request, config),
      (error: unknown) => error instanceof AppError && error.status === 429,
    );
    await assert.rejects(() =>
      callProvider(fakeProvider('ok'), 'extract', request, config),
    );
  });

  it('does not pass a malformed body through', async () => {
    resetBreakers();
    const config = testConfig({
      AI_RETRY_LIMIT: '0',
      AI_BREAKER_THRESHOLD: '5',
    });
    await assert.rejects(
      () =>
        callProvider(
          fakeProvider('malformed'),
          'refine',
          {
            projectId: 'project-1',
            model: 'fake-bad',
            payload: Buffer.from('hi'),
          },
          config,
        ),
      (error: unknown) => error instanceof AppError && error.status === 500,
    );
  });
});
