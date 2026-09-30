import type { AppConfig } from '../../config/schema.js';
import {
  type AppError,
  internalError,
  invalidRequest,
  payloadTooLarge,
  unavailable,
} from '../../domain/errors.js';
import type { AiProvider, AiRequest, AiResult } from './provider.js';

function object(
  value: unknown,
  failure: () => AppError,
): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value))
    throw failure();
  return value as Record<string, unknown>;
}

const invalidPayload = (): AppError =>
  invalidRequest('Invalid analysis payload.');

/// Maps a provider refusal. A refused payload is the caller's fault and a
/// refused key or configured model is this deployment's; neither is retried.
/// Throttling, timeouts and provider faults stay transient.
function refusal(status: number, configuredModel: boolean): AppError {
  if (status === 401 || status === 403 || (status === 404 && configuredModel))
    return unavailable();
  if (status === 413) return payloadTooLarge();
  if (status >= 400 && status < 500 && status !== 408 && status !== 429)
    return invalidRequest('The analysis provider refused this request.');
  return internalError();
}

/** Gemini generateContent adapter. Prompts and media are composed on the device. */
export function httpProvider(
  config: AppConfig,
  request: typeof fetch = fetch,
): AiProvider {
  const key = config.aiProviderKey;
  async function call(input: AiRequest): Promise<AiResult> {
    if (!key) throw unavailable();
    const configuredModel = input.model === 'default';
    const model = configuredModel ? config.aiProviderModel : input.model;
    if (!/^[A-Za-z0-9._-]+$/.test(model))
      throw invalidRequest('Invalid model.');
    let decoded: unknown;
    try {
      decoded = JSON.parse(input.payload.toString('utf8'));
    } catch {
      throw invalidPayload();
    }
    const envelope = object(decoded, invalidPayload);
    if (
      typeof envelope['instructions'] !== 'string' ||
      !Array.isArray(envelope['media']) ||
      (envelope['responseMimeType'] !== 'application/json' &&
        envelope['responseMimeType'] !== 'text/plain')
    )
      throw invalidPayload();
    const parts: unknown[] = [
      { text: JSON.stringify(object(envelope['data'], invalidPayload)) },
    ];
    for (const value of envelope['media']) {
      const media = object(value, invalidPayload);
      if (
        typeof media['mimeType'] !== 'string' ||
        typeof media['base64'] !== 'string' ||
        !/^(image|audio)\/[a-zA-Z0-9.+-]+$/.test(media['mimeType'])
      )
        throw invalidRequest('Invalid analysis media.');
      parts.push({
        inlineData: { mimeType: media['mimeType'], data: media['base64'] },
      });
    }
    // Only documented GenerateContentRequest fields: the API rejects others.
    const response = await request(
      `${config.aiProviderUrl}/models/${model}:generateContent`,
      {
        method: 'POST',
        redirect: 'error',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: envelope['instructions'] }] },
          contents: [{ role: 'user', parts }],
          generationConfig: { responseMimeType: envelope['responseMimeType'] },
        }),
        signal:
          input.signal === undefined
            ? AbortSignal.timeout(config.aiTimeoutMs)
            : AbortSignal.any([
                input.signal,
                AbortSignal.timeout(config.aiTimeoutMs),
              ]),
      },
    );
    if (!response.ok) throw refusal(response.status, configuredModel);
    const output: unknown = await response.json();
    const root = object(output, internalError);
    const candidates = root['candidates'];
    if (!Array.isArray(candidates) || candidates.length === 0)
      throw internalError();
    const candidate = object(candidates[0], internalError);
    if (candidate['finishReason'] !== 'STOP') throw internalError();
    const content = object(candidate['content'], internalError);
    if (!Array.isArray(content['parts'])) throw internalError();
    const text = content['parts']
      .map((part: unknown) => {
        const value = object(part, internalError);
        return value['thought'] === true
          ? ''
          : typeof value['text'] === 'string'
            ? value['text']
            : '';
      })
      .join('');
    if (text.length === 0 || text.includes(key)) throw internalError();
    return { text, model };
  }
  return { extract: call, ocr: call, transcribe: call, refine: call };
}
