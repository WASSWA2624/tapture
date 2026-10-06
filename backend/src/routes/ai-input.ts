import type {
  AiBilling,
  ProcessingIdentity,
  ProviderName,
} from '../domain/ai.js';
import { invalidRequest } from '../domain/errors.js';
import { objectBody } from '../http.js';

function text(value: unknown, maximum = 256): string {
  if (typeof value !== 'string' || value.length === 0 || value.length > maximum)
    throw invalidRequest('Invalid analysis identifier.');
  return value;
}

export function providerName(value: unknown): ProviderName {
  if (value !== 'gemini' && value !== 'openai')
    throw invalidRequest('Unknown analysis provider.');
  return value;
}

function billing(value: unknown): AiBilling | undefined {
  if (value === undefined) return undefined;
  const row = objectBody(value, ['kind', 'provider']);
  if (row['kind'] !== 'managed' && row['kind'] !== 'personal')
    throw invalidRequest('Unknown analysis billing account.');
  return { kind: row['kind'], provider: providerName(row['provider']) };
}

function processing(value: unknown): ProcessingIdentity | undefined {
  if (value === undefined) return undefined;
  const row = objectBody(value, [
    'version',
    'projectRevision',
    'recordId',
    'requestHash',
    'idempotencyKey',
  ]);
  const requestHash = text(row['requestHash']);
  const idempotencyKey = text(row['idempotencyKey']);
  if (
    row['version'] !== 1 ||
    !/^[a-f0-9]{64}$/.test(requestHash) ||
    !/^[a-f0-9]{64}$/.test(idempotencyKey)
  )
    throw invalidRequest('Invalid processing version or content hash.');
  return {
    version: 1,
    projectRevision: text(row['projectRevision']),
    recordId: text(row['recordId']),
    requestHash,
    idempotencyKey,
  };
}

/** Exact envelope bytes make versioned hashes portable between JSON encoders. */
function envelope(value: unknown): Buffer {
  if (
    typeof value === 'string' &&
    /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(
      value,
    )
  )
    return Buffer.from(value, 'base64');
  if (typeof value === 'object' && value !== null && !Array.isArray(value))
    return Buffer.from(JSON.stringify(value), 'utf8');
  throw invalidRequest('Missing or invalid payload.');
}

export function aiInput(body: unknown) {
  const row = objectBody(body, [
    'projectId',
    'model',
    'payload',
    'billing',
    'processing',
    'maxCost',
  ]);
  const account = billing(row['billing']);
  const identity = processing(row['processing']);
  const maxCost = row['maxCost'];
  if (
    maxCost !== undefined &&
    (typeof maxCost !== 'number' || !Number.isFinite(maxCost) || maxCost < 0)
  )
    throw invalidRequest(
      'The approved maximum cost must be a finite non-negative number.',
    );
  return {
    projectId: text(row['projectId']),
    model: text(row['model'], 128),
    payload: envelope(row['payload']),
    ...(account === undefined ? {} : { billing: account }),
    ...(identity === undefined ? {} : { processing: identity }),
    ...(maxCost === undefined ? {} : { maxCost }),
  };
}
