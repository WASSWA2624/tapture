import { requestContext } from '../middleware/request_context.js';

const secretKey =
  /password|token|secret|authorization|cookie|api[_-]?key|credential/i;
const secretValue = /sk-[A-Za-z0-9]|AKIA[A-Z0-9]{8}|Bearer\s+\S+/;

export function redact(value: unknown): unknown {
  if (typeof value === 'string') {
    return secretValue.test(value) ? '[redacted]' : value;
  }
  if (Array.isArray(value)) return value.map(redact);
  if (value !== null && typeof value === 'object') {
    const copy: Record<string, unknown> = {};
    for (const [key, nested] of Object.entries(value)) {
      copy[key] = secretKey.test(key) ? '[redacted]' : redact(nested);
    }
    return copy;
  }
  return value;
}

export interface Logger {
  info(event: string, fields?: Record<string, unknown>): void;
  warn(event: string, fields?: Record<string, unknown>): void;
  error(event: string, fields?: Record<string, unknown>): void;
}

export function createLogger(
  write: (line: string) => void = (line) => {
    process.stdout.write(`${line}\n`);
  },
): Logger {
  const emit = (
    level: string,
    event: string,
    fields: Record<string, unknown> = {},
  ): void => {
    const requestId = requestContext.getStore()?.requestId ?? null;
    write(JSON.stringify(redact({ level, event, requestId, ...fields })));
  };
  return {
    info: (event, fields) => emit('info', event, fields),
    warn: (event, fields) => emit('warn', event, fields),
    error: (event, fields) => emit('error', event, fields),
  };
}

export const log = createLogger();
