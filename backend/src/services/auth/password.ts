import { randomBytes } from 'node:crypto';
import { argon2id, argon2Verify } from 'hash-wasm';
import type { AppConfig } from '../../config/schema.js';

const dummyHashes = new Map<string, Promise<string>>();

function parameters(config: AppConfig): string {
  return `m=${config.argonMemoryKib},t=${config.argonIterations},p=${config.argonParallelism}`;
}

/// Argon2id hash. The only password algorithm this process accepts.
export async function hashPassword(
  password: string,
  config: AppConfig,
): Promise<string> {
  const hash = argon2id({
    password,
    salt: randomBytes(16),
    parallelism: config.argonParallelism,
    iterations: config.argonIterations,
    memorySize: config.argonMemoryKib,
    hashLength: 32,
    outputType: 'encoded',
  });
  // A successful hash also primes timing padding without extra Argon work.
  if (!dummyHashes.has(parameters(config)))
    dummyHashes.set(parameters(config), hash);
  return hash;
}

/// Warm once before accepting requests; each failed login then verifies once.
export async function warmPasswordVerification(
  config: AppConfig,
): Promise<void> {
  const key = parameters(config);
  if (!dummyHashes.has(key))
    await hashPassword(randomBytes(32).toString('hex'), config);
  await dummyHashes.get(key);
}

export function passwordNeedsRehash(
  encoded: string,
  config: AppConfig,
): boolean {
  return !encoded.startsWith(`$argon2id$v=19$${parameters(config)}$`);
}

/// Verifies a password. A missing hash still runs Argon2id so timings match.
export async function verifyPassword(
  password: string,
  encoded: string,
  config: AppConfig,
): Promise<boolean> {
  await warmPasswordVerification(config);
  const hash =
    encoded.length > 0 ? encoded : await dummyHashes.get(parameters(config));
  if (hash === undefined)
    throw new Error('Password verification is not initialized.');
  const ok = await argon2Verify({ password, hash });
  return encoded.length > 0 && ok;
}
