import {
  internalError,
  invalidRequest,
  type AppError,
} from '../../domain/errors.js';
import type { TokenUsage } from '../../domain/ai.js';

export function providerObject(
  value: unknown,
  failure: () => AppError = internalError,
): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value))
    throw failure();
  return value as Record<string, unknown>;
}

/** Refuse an explicitly reported model change instead of silently changing billing. */
export function assertProviderModel(
  root: Record<string, unknown>,
  field: string,
  selected: string,
): void {
  if (root[field] !== undefined && root[field] !== selected)
    throw internalError();
}

export function providerTokens(
  value: unknown,
  fields: readonly [string, string, string],
): TokenUsage | undefined {
  if (value === undefined) return undefined;
  const row = providerObject(value);
  const result: Record<string, number> = {};
  fields.forEach((field, index) => {
    const count = row[field];
    if (count === undefined) return;
    if (
      typeof count !== 'number' ||
      !Number.isSafeInteger(count) ||
      count < 0 ||
      count > 2_147_483_647
    )
      throw internalError();
    const target = ['inputTokens', 'outputTokens', 'totalTokens'][index];
    if (target !== undefined) result[target] = count;
  });
  return result;
}

export function providerEnvelope(payload: Buffer) {
  const failure = () => invalidRequest('Invalid analysis payload.');
  let decoded: unknown;
  try {
    decoded = JSON.parse(payload.toString('utf8'));
  } catch {
    throw failure();
  }
  const envelope = providerObject(decoded, failure);
  if (
    typeof envelope['instructions'] !== 'string' ||
    !Array.isArray(envelope['media']) ||
    (envelope['responseMimeType'] !== 'application/json' &&
      envelope['responseMimeType'] !== 'text/plain')
  )
    throw failure();
  const media = envelope['media'].map((entry: unknown) => {
    const row = providerObject(entry, failure);
    if (
      typeof row['mimeType'] !== 'string' ||
      typeof row['base64'] !== 'string' ||
      !/^(image|audio)\/[A-Za-z0-9.+-]+$/.test(row['mimeType']) ||
      !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(
        row['base64'],
      )
    )
      throw invalidRequest('Invalid analysis media.');
    return { mimeType: row['mimeType'], base64: row['base64'] };
  });
  return {
    instructions: envelope['instructions'],
    data: providerObject(envelope['data'], failure),
    media,
    responseMimeType: envelope['responseMimeType'],
  };
}
