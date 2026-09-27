/// A package is due when its expiry is at or before the injected clock.
export function shouldPurge(expiresAt: string, now: Date): boolean {
  return Date.parse(expiresAt) <= now.getTime();
}
