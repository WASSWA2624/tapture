import type { NextFunction, Request, Response } from 'express';

export function securityHeaders(
  _req: Request,
  res: Response,
  next: NextFunction,
): void {
  res.setHeader('x-content-type-options', 'nosniff');
  res.setHeader('referrer-policy', 'no-referrer');
  res.setHeader(
    'strict-transport-security',
    'max-age=63072000; includeSubDomains',
  );
  next();
}
