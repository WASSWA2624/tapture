export type ErrorCode =
  | 'invalid_request'
  | 'unauthorized'
  | 'invalid_credentials'
  | 'forbidden'
  | 'not_found'
  | 'conflict'
  | 'payload_too_large'
  | 'rate_limited'
  | 'quota_exceeded'
  | 'internal'
  | 'unavailable';

/// One failure the API is allowed to return. The message is safe to show.
export class AppError extends Error {
  readonly code: ErrorCode;
  readonly status: number;
  readonly publicMessage: string;
  readonly details?: Record<string, unknown>;

  constructor(
    code: ErrorCode,
    status: number,
    publicMessage: string,
    details?: Record<string, unknown>,
  ) {
    super(publicMessage);
    this.name = 'AppError';
    this.code = code;
    this.status = status;
    this.publicMessage = publicMessage;
    if (details !== undefined) this.details = details;
  }
}

export const invalidRequest = (
  message: string,
  details?: Record<string, unknown>,
): AppError => new AppError('invalid_request', 400, message, details);

export const unauthorized = (): AppError =>
  new AppError('unauthorized', 401, 'Sign in to continue.');

export const invalidCredentials = (): AppError =>
  new AppError(
    'invalid_credentials',
    401,
    'The email or password is not valid.',
  );

export const forbidden = (): AppError =>
  new AppError('forbidden', 403, 'That action is not available.');

export const notFound = (): AppError =>
  new AppError('not_found', 404, 'Not found.');

export const conflict = (message: string): AppError =>
  new AppError('conflict', 409, message);

export const payloadTooLarge = (): AppError =>
  new AppError('payload_too_large', 413, 'That upload is too large.');

export const rateLimited = (): AppError =>
  new AppError('rate_limited', 429, 'Too many attempts. Wait and try again.');

export const quotaExceeded = (): AppError =>
  new AppError(
    'quota_exceeded',
    429,
    'The project storage ceiling is reached.',
  );

export const internalError = (): AppError =>
  new AppError('internal', 500, 'Something went wrong.');

/// A dependency this deployment has not configured; retrying cannot help.
export const unavailable = (): AppError =>
  new AppError('unavailable', 503, 'This service is not available.');
