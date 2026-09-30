import { requestContext } from '../middleware/request_context.js';

const secretKey =
  /password|token|secret|authorization|cookie|api[_-]?key|credential|caption|transcript|field.?value|file.?name|payload|prompt|instructions|body|image|audio|photo/i;
const secretValue =
  /sk-[A-Za-z0-9]|AKIA[A-Z0-9]{8}|AIza[0-9A-Za-z_-]{35}|Bearer\s+\S+/;

const metadataFields = new Set([
  'route',
  'userId',
  'deviceId',
  'projectId',
  'model',
  'byteSize',
  'durationMs',
  'outcome',
  'cost',
  'status',
  'code',
  'name',
  'limit',
  'port',
  'deleted',
  'bytesReclaimed',
  'oldestAgeSeconds',
  'failures',
  'transientDeleted',
]);

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
    const context = requestContext.getStore();
    const metadata = Object.fromEntries(
      Object.entries(fields).map(([key, value]) => [
        key,
        metadataFields.has(key) &&
        (value === null ||
          ['string', 'number', 'boolean'].includes(typeof value))
          ? value
          : '[redacted]',
      ]),
    );
    // Context is authoritative; a caller cannot overwrite the request identity,
    // event or timestamp through an incidental field spread.
    write(
      JSON.stringify(
        redact({
          ...metadata,
          level,
          event,
          at: new Date().toISOString(),
          requestId: context?.requestId ?? null,
          route: context?.route ?? metadata['route'] ?? null,
          userId: context?.principal?.userId ?? metadata['userId'] ?? null,
          deviceId:
            context?.principal?.deviceId ?? metadata['deviceId'] ?? null,
        }),
      ),
    );
  };
  return {
    info: (event, fields) => emit('info', event, fields),
    warn: (event, fields) => emit('warn', event, fields),
    error: (event, fields) => emit('error', event, fields),
  };
}

export const log = createLogger();
