import type { TokenUsage } from '../../domain/ai.js';

export interface AiRequest {
  projectId: string;
  model: string;
  payload: Buffer;
  signal?: AbortSignal;
  /** Distinguishes a configured provider and billing account for breaker isolation. */
  accountId?: string;
}

export interface AiResult {
  text: string;
  model: string;
  usage?: TokenUsage;
}

export interface AiProvider {
  extract(request: AiRequest): Promise<AiResult>;
  ocr(request: AiRequest): Promise<AiResult>;
  transcribe(request: AiRequest): Promise<AiResult>;
  refine(request: AiRequest): Promise<AiResult>;
}

export type FakeMode = 'ok' | 'fail' | 'timeout' | 'malformed';

/// Test double. It never sees a provider key.
export function fakeProvider(mode: FakeMode): AiProvider {
  const answer = async (request: AiRequest): Promise<AiResult> => {
    if (mode === 'fail') throw new Error('provider failed');
    if (mode === 'timeout') throw new Error('timeout');
    if (mode === 'malformed') return { text: '', model: request.model };
    return { text: `ok:${request.payload.length}`, model: request.model };
  };
  return { extract: answer, ocr: answer, transcribe: answer, refine: answer };
}
