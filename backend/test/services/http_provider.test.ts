import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import { httpProvider } from '../../src/services/ai/http_provider.js';
import { testConfig } from '../helpers.js';

// The documented top-level v1beta GenerateContentRequest fields. The API
// refuses any other name with 400 INVALID_ARGUMENT.
const documentedFields = new Set([
  'contents',
  'systemInstruction',
  'generationConfig',
  'safetySettings',
  'tools',
  'toolConfig',
  'cachedContent',
]);

const instructions = 'Device-owned extraction instructions';
const input = {
  projectId: 'project',
  model: 'default',
  payload: Buffer.from(
    JSON.stringify({
      instructions,
      data: { caption: 'quoted caption' },
      media: [
        { mimeType: 'image/jpeg', base64: 'AQID' },
        { mimeType: 'audio/wav', base64: 'BAUG' },
      ],
      responseMimeType: 'application/json',
    }),
  ),
};
const config = () =>
  testConfig({
    AI_PROVIDER_KEY: 'test-provider-credential',
    AI_PROVIDER_MODEL: 'test-model',
  });

/// The API status the adapter raises for one provider reply.
async function failureStatus(
  response: () => Response,
  model = 'default',
): Promise<number | undefined> {
  try {
    await httpProvider(config(), async () => response()).extract({
      ...input,
      model,
    });
  } catch (error) {
    return error instanceof AppError ? error.status : undefined;
  }
  return undefined;
}

describe('Gemini provider adapter', () => {
  it('forwards device instructions and inline media using the documented REST shape', async () => {
    let calls = 0;
    const provider = httpProvider(config(), async (url, init) => {
      calls++;
      assert.equal(
        url,
        'https://generativelanguage.googleapis.com/v1beta/models/test-model:generateContent',
      );
      assert.equal(init?.method, 'POST');
      assert.equal(init?.redirect, 'error');
      const headers = init?.headers as Record<string, string>;
      assert.equal(headers['x-goog-api-key'], 'test-provider-credential');
      const body = JSON.parse(init?.body as string) as Record<string, unknown>;
      assert.deepEqual(body['systemInstruction'], {
        parts: [{ text: instructions }],
      });
      assert.deepEqual(body['contents'], [
        {
          role: 'user',
          parts: [
            { text: '{"caption":"quoted caption"}' },
            { inlineData: { mimeType: 'image/jpeg', data: 'AQID' } },
            { inlineData: { mimeType: 'audio/wav', data: 'BAUG' } },
          ],
        },
      ]);
      assert.deepEqual(
        Object.keys(body).filter((field) => !documentedFields.has(field)),
        [],
      );
      assert.equal('store' in body, false);
      assert.equal(
        JSON.stringify(body).includes('test-provider-credential'),
        false,
      );
      return new Response(
        JSON.stringify({
          candidates: [
            {
              finishReason: 'STOP',
              content: {
                parts: [
                  { text: 'private thought', thought: true },
                  { text: '{"fields":{}}' },
                ],
              },
            },
          ],
        }),
        { status: 200 },
      );
    });
    for (const operation of [
      'extract',
      'ocr',
      'transcribe',
      'refine',
    ] as const) {
      assert.deepEqual(await provider[operation](input), {
        text: '{"fields":{}}',
        model: 'test-model',
      });
    }
    assert.equal(calls, 4);
  });

  it('rejects unconfigured keys, provider failures, blocked output and key echoes', async () => {
    let calls = 0;
    const never = async () => {
      calls++;
      return new Response('{}');
    };
    await assert.rejects(
      () => httpProvider(testConfig(), never).extract(input),
      (error: unknown) =>
        error instanceof AppError &&
        error.status === 503 &&
        error.code === 'unavailable',
    );
    assert.equal(calls, 0);
    for (const response of [
      new Response('{}', { status: 429 }),
      new Response('{}', { status: 200 }),
      new Response(
        JSON.stringify({
          candidates: [
            {
              finishReason: 'MAX_TOKENS',
              content: { parts: [{ text: 'partial' }] },
            },
          ],
        }),
      ),
      new Response(
        JSON.stringify({
          candidates: [
            {
              finishReason: 'STOP',
              content: { parts: [{ text: 'test-provider-credential' }] },
            },
          ],
        }),
      ),
    ]) {
      await assert.rejects(() =>
        httpProvider(config(), async () => response).extract(input),
      );
    }
    await assert.rejects(() =>
      httpProvider(config(), async () => {
        throw new Error('transport');
      }).ocr(input),
    );
  });

  it('separates payload refusals, configuration faults and transient failures', async () => {
    const refused = (status: number) => () => new Response('{}', { status });
    assert.equal(await failureStatus(refused(400)), 400);
    assert.equal(await failureStatus(refused(404), 'requested-model'), 400);
    assert.equal(await failureStatus(refused(413)), 413);
    for (const status of [401, 403, 404]) {
      assert.equal(await failureStatus(refused(status)), 503);
    }
    for (const status of [408, 429, 500, 503]) {
      assert.equal(await failureStatus(refused(status)), 500);
    }
    for (const body of ['[]', JSON.stringify({ candidates: [null] })]) {
      assert.equal(await failureStatus(() => new Response(body)), 500);
    }
  });
});
