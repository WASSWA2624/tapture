import {
  createCipheriv,
  createDecipheriv,
  randomBytes,
  randomUUID,
} from 'node:crypto';
import type { AppConfig } from '../../config/schema.js';
import type { CredentialRow, ProviderName } from '../../domain/ai.js';
import { invalidRequest, notFound, unavailable } from '../../domain/errors.js';
import { can, type Principal } from '../../domain/permissions.js';
import type { Repository } from '../../repositories/repository.js';
import { credentialProvider } from './catalogue.js';

function encryptionKey(config: AppConfig): Buffer {
  if (config.aiCredentialEncryptionKey === '') throw unavailable();
  return Buffer.from(config.aiCredentialEncryptionKey, 'hex');
}

function scope(principal: Principal): void {
  if (!can(principal, 'aiProxy')) throw notFound();
}

function associatedData(
  row: Pick<CredentialRow, 'userId' | 'provider' | 'revision'>,
): Buffer {
  return Buffer.from(
    JSON.stringify([row.userId, row.provider, row.revision]),
    'utf8',
  );
}

export async function credentialStatus(
  store: Repository,
  principal: Principal,
  provider: ProviderName,
  config: AppConfig,
) {
  scope(principal);
  credentialProvider(config, provider);
  return {
    provider,
    configured:
      (await store.aiCredential(principal.userId, provider)) !== undefined,
  };
}

export async function saveCredential(
  store: Repository,
  config: AppConfig,
  principal: Principal,
  provider: ProviderName,
  apiKey: string,
): Promise<void> {
  scope(principal);
  credentialProvider(config, provider);
  if (
    apiKey.length === 0 ||
    apiKey.length > 4096 ||
    apiKey.trim() !== apiKey ||
    /[\r\n\0]/.test(apiKey)
  )
    throw invalidRequest('Enter a valid provider credential.');
  const revision = randomUUID();
  const identity = { userId: principal.userId, provider, revision };
  const key = encryptionKey(config);
  const nonce = randomBytes(12);
  let encryptedKey: string;
  try {
    const cipher = createCipheriv('aes-256-gcm', key, nonce);
    cipher.setAAD(associatedData(identity));
    const ciphertext = Buffer.concat([
      cipher.update(apiKey, 'utf8'),
      cipher.final(),
    ]);
    encryptedKey = [
      'v1',
      nonce.toString('base64url'),
      cipher.getAuthTag().toString('base64url'),
      ciphertext.toString('base64url'),
    ].join(':');
  } finally {
    key.fill(0);
  }
  await store.withTransaction(async (tx) => {
    await tx.saveAiCredential({
      ...identity,
      encryptedKey,
      createdAt: new Date().toISOString(),
    });
    await tx.recordAudit({
      actorId: principal.userId,
      action: 'ai_credential_saved',
      target: provider,
      before: null,
      after: { configured: true },
    });
  });
}

export async function deleteCredential(
  store: Repository,
  principal: Principal,
  provider: ProviderName,
  config: AppConfig,
): Promise<void> {
  scope(principal);
  credentialProvider(config, provider);
  await store.withTransaction(async (tx) => {
    await tx.deleteAiCredential(principal.userId, provider);
    await tx.recordAudit({
      actorId: principal.userId,
      action: 'ai_credential_deleted',
      target: provider,
      before: null,
      after: { configured: false },
    });
  });
}

/** Only the adapter receives plaintext, for the lifetime of one chosen request. */
export function decryptCredential(
  config: AppConfig,
  row: CredentialRow,
): string {
  const key = encryptionKey(config);
  let plaintext: Buffer | undefined;
  try {
    const [version, nonce, tag, ciphertext, extra] =
      row.encryptedKey.split(':');
    if (
      version !== 'v1' ||
      nonce === undefined ||
      tag === undefined ||
      ciphertext === undefined ||
      extra !== undefined
    )
      throw unavailable();
    const decipher = createDecipheriv(
      'aes-256-gcm',
      key,
      Buffer.from(nonce, 'base64url'),
    );
    decipher.setAAD(associatedData(row));
    decipher.setAuthTag(Buffer.from(tag, 'base64url'));
    plaintext = Buffer.concat([
      decipher.update(Buffer.from(ciphertext, 'base64url')),
      decipher.final(),
    ]);
    return plaintext.toString('utf8');
  } catch {
    throw unavailable();
  } finally {
    key.fill(0);
    plaintext?.fill(0);
  }
}
