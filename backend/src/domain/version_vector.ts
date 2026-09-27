export type VersionVector = Record<string, number>;

/// Merges two vectors by taking the higher counter for each device.
export function mergeVectors(
  left: VersionVector,
  right: VersionVector,
): VersionVector {
  const merged: VersionVector = { ...left };
  for (const [device, counter] of Object.entries(right)) {
    const current = merged[device] ?? 0;
    merged[device] = Math.max(current, counter);
  }
  return merged;
}

/// True when every counter in [incoming] is already known.
export function vectorDominates(
  known: VersionVector,
  incoming: VersionVector,
): boolean {
  return Object.entries(incoming).every(
    ([device, counter]) => (known[device] ?? 0) >= counter,
  );
}
