export interface Mismatch {
  path: string;
  field: string;
}

/// Reports every path or field the running surface does not document.
export function compareContract(
  documented: string[],
  actual: Array<{ path: string; field?: string }>,
): Mismatch[] {
  const known = new Set(documented);
  const mismatches: Mismatch[] = [];
  for (const route of actual) {
    if (!known.has(route.path)) {
      mismatches.push({ path: route.path, field: route.field ?? 'path' });
    } else if (route.field !== undefined && route.field !== 'path') {
      mismatches.push({ path: route.path, field: route.field });
    }
  }
  return mismatches;
}
