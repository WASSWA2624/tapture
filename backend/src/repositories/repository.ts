import type { Store } from './store.js';

/// The asynchronous persistence boundary; the memory implementation remains a test fake.
export type Repository = {
  [Key in Exclude<keyof Store, 'withTransaction'>]: Store[Key] extends (
    ...args: infer Args
  ) => infer Value
    ? (...args: Args) => Value | Promise<Value>
    : never;
} & {
  withTransaction<T>(work: (repository: Repository) => Promise<T>): Promise<T>;
};
