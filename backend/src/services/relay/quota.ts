/// True when [incoming] bytes still fit under the ceiling.
export function withinCeiling(
  used: number,
  incoming: number,
  ceiling: number,
): boolean {
  return used + incoming <= ceiling;
}
