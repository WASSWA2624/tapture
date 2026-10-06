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

/** Stateless Responses API adapter: inline images, no remote files or background job. */
export function openaiProvider(
  config: AppConfig,
  key: string,
  request: typeof fetch = fetch,
): AiProvider {
  const call = async (input: AiRequest): Promise<AiResult> => {
    if (key === '') throw unavailable();
    const model =
      input.model === 'default' ? config.aiOpenaiModel : input.model;
    if (!/^[A-Za-z0-9._-]+$/.test(model)) throw unavailable();
    const envelope = providerEnvelope(input.payload);
    const content: unknown[] = [
      { type: 'input_text', text: JSON.stringify(envelope.data) },
    ];
    for (const media of envelope.media) {
      if (!/^image\/(jpeg|png|webp|gif)$/.test(media.mimeType))
        throw invalidRequest(
          'This provider accepts photo and text evidence. Use your saved transcript for audio captions.',
        );
      content.push({
        type: 'input_image',
        image_url: `data:${media.mimeType};base64,${media.base64}`,
        detail: 'auto',
      });
    }
    const response = await request(`${config.aiOpenaiUrl}/responses`, {
      method: 'POST',
      redirect: 'error',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${key}`,
      },
      body: JSON.stringify({
        model,
        instructions: envelope.instructions,
        input: [{ role: 'user', content }],
        store: false,
        background: false,
        max_output_tokens: config.aiMaxOutputTokens,
        text: {
          format: {
            type:
              envelope.responseMimeType === 'application/json'
                ? 'json_object'
                : 'text',
          },
        },
      }),
      signal:
        input.signal === undefined
          ? AbortSignal.timeout(config.aiTimeoutMs)
          : AbortSignal.any([
              input.signal,
              AbortSignal.timeout(config.aiTimeoutMs),
            ]),
    });
    if (!response.ok) throw providerRefusal(response.status, true);
    const root = providerObject(await response.json());
    assertProviderModel(root, 'model', model);
    if (root['status'] !== 'completed' || !Array.isArray(root['output']))
      throw internalError();
    const parts: string[] = [];
    for (const item of root['output']) {
      const row = providerObject(item);
      if (row['type'] !== 'message') continue;
      if (!Array.isArray(row['content'])) throw internalError();
      for (const part of row['content']) {
        const value = providerObject(part);
        if (value['type'] === 'refusal')
          throw invalidRequest('The analysis provider refused this request.');
        if (
          value['type'] === 'output_text' &&
          typeof value['text'] === 'string'
        )
          parts.push(value['text']);
      }
    }
    const text = parts.join('');
    if (text === '' || text.includes(key)) throw internalError();
    const usage = providerTokens(root['usage'], [
      'input_tokens',
      'output_tokens',
      'total_tokens',
    ]);
    return { text, model, ...(usage === undefined ? {} : { usage }) };
  };
  return { extract: call, ocr: call, transcribe: call, refine: call };
}
