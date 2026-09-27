import type { AppConfig } from './config/schema.js';
import type { AppPool } from './db/pool.js';
import type { Logger } from './observability/logger.js';
import type { Store } from './repositories/store.js';
import type { AiProvider } from './services/ai/provider.js';
import type { Metrics } from './services/metrics/metrics.js';

export interface Deps {
  store: Store;
  config: AppConfig;
  pool: AppPool;
  provider: AiProvider;
  metrics: Metrics;
  log: Logger;
}
