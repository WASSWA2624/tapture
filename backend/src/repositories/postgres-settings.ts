import type { RuntimeSetting } from './settings.js';
import type { Sql } from './sql.js';

export function settingsRepository(sql: Sql) {
  return {
    runtimeSettings: () =>
      sql.rows<RuntimeSetting>(
        'SELECT name,fingerprint,metadata FROM runtime_settings ORDER BY name',
      ),
    saveRuntimeSetting: (row: RuntimeSetting) =>
      sql.write(
        'INSERT INTO runtime_settings(name,fingerprint,metadata) VALUES($1,$2,$3) ON CONFLICT(name) DO UPDATE SET fingerprint=EXCLUDED.fingerprint,metadata=EXCLUDED.metadata,updated_at=now()',
        [row.name, row.fingerprint, row.metadata],
      ),
  };
}
