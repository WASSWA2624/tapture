import { parseConfig, type AppConfig } from './schema.js';

/// Loaded once at import. A missing secret or an illegal retention refuses boot.
export const config: AppConfig = parseConfig(process.env);
