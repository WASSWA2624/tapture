import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  AppError,
  invalidRequest,
  payloadTooLarge,
  unavailable,
} from '../../src/domain/errors.js';
import { httpProvider } from '../../src/services/ai/http_provider.js';
import {
  fakeProvider,
  type AiProvider,
  type AiResult,
} from '../../src/services/ai/provider.js';
import {
  callProvider,
  resetBreakers,
} from '../../src/services/ai/resilience.js';
import { testConfig } from '../helpers.js';

/// A provider that refuses every call with [fault] and counts the attempts.
function refusing(fault: AppError): {
  provider: AiProvider;
  calls: () => number;
} {
  let calls = 0;
  const refuse = async (): Promise<AiResult> => {
    calls += 1;
    throw fault;
  };
  return {
    provider: {
      extract: refuse,
      ocr: refuse,
      transcribe: refuse,
      refine: refuse,
    },
    calls: () => calls,
  };
}

describe('ai resilience', () => {
  it('retries a failure and opens the breaker', async () => {
    resetBreakers();
    const config = testConfig({
      AI_RETRY_LIMIT: '1',
      AI_BREAKER_THRESHOLD: '1',
      // The breaker stays open for the timeout; keep it well past the retry
      // back-off so coarse (~16 ms) Windows timers cannot close it first.
      AI_TIMEOUT_MS: '1000',
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

  it('passes client and configuration faults through without a retry or a breaker count', async () => {
    resetBreakers();
    const config = testConfig({
      AI_RETRY_LIMIT: '2',
      AI_BREAKER_THRESHOLD: '1',
      AI_TIMEOUT_MS: '1000',
    });
    const request = {
      projectId: 'project-1',
      model: 'default',
      payload: Buffer.from('hi'),
    };
    for (const fault of [
      invalidRequest('Invalid analysis payload.'),
      payloadTooLarge(),
      unavailable(),
    ]) {
      const refused = refusing(fault);
      await assert.rejects(
        () => callProvider(refused.provider, 'extract', request, config),
        (error: unknown) => error === fault,
      );
      assert.equal(refused.calls(), 1);
    }
    const healthy = await callProvider(
      fakeProvider('ok'),
      'extract',
      request,
      config,
    );
    assert.match(healthy.text, /^ok:/);
  });

  it('answers a provider payload refusal with 400 after one attempt', async () => {
    resetBreakers();
    let calls = 0;
    const provider = httpProvider(
      testConfig({
        AI_PROVIDER_KEY: 'test-provider-credential',
        AI_PROVIDER_MODEL: 'test-model',
      }),
      async () => {
        calls += 1;
        return new Response('{}', { status: 400 });
      },
    );
    const payload = Buffer.from(
      JSON.stringify({
        instructions: 'Read the attached images.',
        data: {},
        media: [],
        responseMimeType: 'text/plain',
      }),
    );
    await assert.rejects(
      () =>
        callProvider(
          provider,
          'ocr',
          { projectId: 'project-1', model: 'default', payload },
          testConfig({ AI_RETRY_LIMIT: '2', AI_BREAKER_THRESHOLD: '1' }),
        ),
      (error: unknown) =>
        error instanceof AppError &&
        error.status === 400 &&
        error.code === 'invalid_request',
    );
    assert.equal(calls, 1);
  });
});
