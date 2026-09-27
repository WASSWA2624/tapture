import type { Store } from './store.js';

/// Runs [work] in one transaction. A throw rolls the store back.
export async function withTransaction<T>(
  store: Store,
  work: (store: Store) => Promise<T>,
): Promise<T> {
  return store.withTransaction(work);
}
