import { randomBytes } from 'node:crypto';
import { argon2id, argon2Verify } from 'hash-wasm';
import type { AppConfig } from '../../config/schema.js';

/// Argon2id hash. The only password algorithm this process accepts.
export async function hashPassword(
  password: string,
  config: AppConfig,
): Promise<string> {
  return argon2id({
    password,
    salt: randomBytes(16),
    parallelism: config.argonParallelism,
    iterations: config.argonIterations,
    memorySize: config.argonMemoryKib,
    hashLength: 32,
    outputType: 'encoded',
  });
}

/// Verifies a password. A missing hash still runs Argon2id so timings match.
export async function verifyPassword(
  password: string,
  encoded: string,
  config: AppConfig,
): Promise<boolean> {
  const hash =
    encoded.length > 0 ? encoded : await hashPassword('timing-pad', config);
  const ok = await argon2Verify({ password, hash });
  return encoded.length > 0 && ok;
}
