/// Hard ceiling. A configured value above this refuses to boot.
export const RETENTION_HARD_MAX_DAYS = 90;

/// Clamps a project retention to the organisation maximum and the hard ceiling.
export function clampRetention(days: number, organisationMax: number): number {
  const ceiling = Math.min(organisationMax, RETENTION_HARD_MAX_DAYS);
  if (!Number.isInteger(days) || days < 1) {
    throw new Error('Retention must be a whole number of days.');
  }
  if (days > ceiling) {
    throw new Error(`Retention cannot exceed ${ceiling} days.`);
  }
  return days;
}
