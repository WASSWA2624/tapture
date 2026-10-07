import { createHash } from 'node:crypto';
import type { AppConfig } from '../config/schema.js';
import type { Repository } from '../repositories/repository.js';
import type { RuntimeSetting } from '../repositories/settings.js';

function setting(
  name: string,
  value: unknown,
  metadata: Record<string, unknown>,
): RuntimeSetting {
  return {
    name,
    fingerprint: createHash('sha256')
      .update(JSON.stringify(value))
      .digest('hex'),
    metadata,
  };
}

/// Audit deployment changes before listen, without recording key material.
export async function auditConfiguration(
  store: Repository,
  config: AppConfig,
): Promise<void> {
  const settings = [
    setting('access_signing_key', config.tokenSecret, {
      configured: config.tokenSecret.length > 0,
    }),
    setting('provider_key', config.aiProviderKey, {
      configured: config.aiProviderKey.length > 0,
    }),
    setting(
      'personal_credential_encryption_key',
      config.aiCredentialEncryptionKey,
      { configured: config.aiCredentialEncryptionKey !== '' },
    ),
    setting(
      'relay_policy',
      [
        config.retentionDays,
        config.packageMaxBytes,
        config.storageCeilingBytes,
        config.organisationStorageCeilingBytes,
      ],
      {
        retentionDays: config.retentionDays,
        packageMaxBytes: config.packageMaxBytes,
        storageCeilingBytes: config.storageCeilingBytes,
        organisationStorageCeilingBytes: config.organisationStorageCeilingBytes,
      },
    ),
    setting(
      'ai_policy',
      [
        config.aiProviderCatalogue,
        config.aiProviderUrl,
        config.aiProvider,
        config.aiGeminiModel,
        config.aiOpenaiModel,
        config.aiOpenaiUrl,
        config.aiModelCostCeilings,
        config.aiMaxOutputTokens,
        config.aiProviderModel,
        config.aiRequestCostCeiling,
        config.aiRetryLimit,
        config.aiTimeoutMs,
        config.aiProjectRequestLimit,
        config.aiOrganisationRequestLimit,
        config.aiProjectDailyRequestLimit,
        config.aiOrganisationDailyRequestLimit,
        config.aiProjectBudget,
        config.aiOrganisationBudget,
        config.aiProjectDailyBudget,
        config.aiOrganisationDailyBudget,
      ],
      {
        providers: config.aiProviderCatalogue.map(
          ({ id, protocol, authMode }) => ({ id, protocol, authMode }),
        ),
        providerUrl: config.aiProviderUrl,
        provider: config.aiProvider,
        geminiModel: config.aiGeminiModel,
        openaiModel: config.aiOpenaiModel,
        openaiUrl: config.aiOpenaiUrl,
        modelCostCeilings: config.aiModelCostCeilings,
        maxOutputTokens: config.aiMaxOutputTokens,
        model: config.aiProviderModel,
        requestCostCeiling: config.aiRequestCostCeiling,
        retryLimit: config.aiRetryLimit,
        timeoutMs: config.aiTimeoutMs,
        projectRequestLimit: config.aiProjectRequestLimit,
        organisationRequestLimit: config.aiOrganisationRequestLimit,
        projectDailyRequestLimit: config.aiProjectDailyRequestLimit,
        organisationDailyRequestLimit: config.aiOrganisationDailyRequestLimit,
        projectBudget: config.aiProjectBudget,
        organisationBudget: config.aiOrganisationBudget,
        projectDailyBudget: config.aiProjectDailyBudget,
        organisationDailyBudget: config.aiOrganisationDailyBudget,
      },
    ),
  ];
  await store.withTransaction(async (tx) => {
    const previous = new Map(
      (await tx.runtimeSettings()).map((row) => [row.name, row]),
    );
    for (const next of settings) {
      const current = previous.get(next.name);
      if (current?.fingerprint === next.fingerprint) continue;
      if (next.name === 'relay_policy')
        await tx.applyRetention(config.retentionDays);
      await tx.saveRuntimeSetting(next);
      await tx.recordAudit({
        actorId: 'deployment',
        action:
          current === undefined
            ? 'configuration_initialized'
            : 'configuration_changed',
        target: next.name,
        before: current?.metadata ?? null,
        after: { ...next.metadata, outcome: 'applied' },
      });
    }
  });
}
