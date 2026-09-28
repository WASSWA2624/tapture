import type { Repository as Store } from './repository.js';
/// Runs [work] in one transaction. A throw rolls the store back.
export async function withTransaction<T>(
  store: Store,
  work: (store: Store) => Promise<T>,
): Promise<T> {
  return await store.withTransaction(work);
}
