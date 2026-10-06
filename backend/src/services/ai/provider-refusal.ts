import {
  internalError,
  invalidRequest,
  payloadTooLarge,
  unavailable,
  type AppError,
} from '../../domain/errors.js';

export function providerRefusal(
  status: number,
  configuredModel: boolean,
): AppError {
  if (status === 401 || status === 403 || (status === 404 && configuredModel))
    return unavailable();
  if (status === 413) return payloadTooLarge();
  if (status >= 400 && status < 500 && status !== 408 && status !== 429)
    return invalidRequest('The analysis provider refused this request.');
  return internalError();
}
