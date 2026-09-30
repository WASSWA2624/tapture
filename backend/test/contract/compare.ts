export interface Mismatch {
  path: string;
  field: string;
}

export interface HttpOperation {
  path: string;
  method: string;
}

/// Reports every path or field the running surface does not document.
export function compareContract(
  documented: HttpOperation[],
  actual: HttpOperation[],
): Mismatch[] {
  const key = (operation: HttpOperation): string =>
    `${operation.method.toUpperCase()} ${operation.path}`;
  const known = new Set(documented.map(key));
  const implemented = new Set(actual.map(key));
  const mismatches: Mismatch[] = [];
  for (const route of actual) {
    if (!known.has(key(route)))
      mismatches.push({ path: route.path, field: route.method });
  }
  for (const route of documented)
    if (!implemented.has(key(route)))
      mismatches.push({ path: route.path, field: `missing ${route.method}` });
  return mismatches;
}
