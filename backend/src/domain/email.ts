/// The one stored and compared form of an account address.
export function normaliseEmail(value: string): string {
  return value.trim().toLowerCase();
}

/// Whether two addresses name the same account, including rows stored before
/// addresses were normalised.
export function sameEmail(left: string, right: string): boolean {
  return normaliseEmail(left) === normaliseEmail(right);
}
