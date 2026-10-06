import type { AppConfig } from '../../config/schema.js';
import {
  internalError,
  invalidRequest,
  unavailable,
} from '../../domain/errors.js';
import type { AiProvider, AiRequest, AiResult } from './provider.js';
import {
  assertProviderModel,
  providerEnvelope,
  providerObject,
  providerTokens,
} from './provider-envelope.js';
import { providerRefusal } from './provider-refusal.js';

/** Gemini generateContent adapter. Prompts and media are composed on the device. */
export function httpProvider(
  config: AppConfig,
  request: typeof fetch = fetch,
  key = config.aiProviderKey,
): AiProvider {
  async function call(input: AiRequest): Promise<AiResult> {
    if (!key) throw unavailable();
    const configuredModel =
      input.model === 'default' ||
      input.model === config.aiGeminiModel ||
      config.aiModelCostCeilings[`gemini:${input.model}`] !== undefined;
    const model =
      input.model === 'default' ? config.aiGeminiModel : input.model;
    if (!/^[A-Za-z0-9._-]+$/.test(model))
      throw invalidRequest('Invalid model.');
    const envelope = providerEnvelope(input.payload);
    const parts: unknown[] = [{ text: JSON.stringify(envelope.data) }];
    for (const media of envelope.media)
      parts.push({
        inlineData: { mimeType: media.mimeType, data: media.base64 },
      });
    const response = await request(
      `${config.aiProviderUrl}/models/${model}:generateContent`,
      {
        method: 'POST',
        redirect: 'error',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: envelope.instructions }] },
          contents: [{ role: 'user', parts }],
          generationConfig: {
            responseMimeType: envelope.responseMimeType,
            maxOutputTokens: config.aiMaxOutputTokens,
          },
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
    if (!response.ok) throw providerRefusal(response.status, configuredModel);
    const root = providerObject(await response.json());
    assertProviderModel(root, 'modelVersion', model);
    const candidates = root['candidates'];
    if (!Array.isArray(candidates) || candidates.length === 0)
      throw internalError();
    const candidate = providerObject(candidates[0]);
    if (candidate['finishReason'] !== 'STOP') throw internalError();
    const content = providerObject(candidate['content']);
    if (!Array.isArray(content['parts'])) throw internalError();
    const text = content['parts']
      .map((part: unknown) => {
        const value = providerObject(part);
        return value['thought'] === true
          ? ''
          : typeof value['text'] === 'string'
            ? value['text']
            : '';
      })
      .join('');
    if (text.length === 0 || text.includes(key)) throw internalError();
    const usage = providerTokens(root['usageMetadata'], [
      'promptTokenCount',
      'candidatesTokenCount',
      'totalTokenCount',
    ]);
    return { text, model, ...(usage === undefined ? {} : { usage }) };
  }
  return { extract: call, ocr: call, transcribe: call, refine: call };
}
