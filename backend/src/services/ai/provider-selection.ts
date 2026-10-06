import { createHash } from 'node:crypto';
import type { AppConfig } from '../../config/schema.js';
import type { AiBilling, ProviderName } from '../../domain/ai.js';
import {
  invalidRequest,
  quotaExceeded,
  unavailable,
} from '../../domain/errors.js';
import { can, type Principal } from '../../domain/permissions.js';
import type { Repository } from '../../repositories/repository.js';
import { credentialStatus, decryptCredential } from './credentials.js';
import { httpProvider } from './http_provider.js';
import { openaiProvider } from './openai-provider.js';
import type { AiProvider } from './provider.js';

export type ProviderFactory = (
  provider: ProviderName,
  key: string,
) => AiProvider;

export function configuredProvider(
  config: AppConfig,
  provider: ProviderName,
  key: string,
): AiProvider {
  return provider === 'gemini'
    ? httpProvider(config, fetch, key)
    : openaiProvider(config, key);
}

function baseModel(config: AppConfig, provider: ProviderName): string {
  return provider === 'gemini' ? config.aiGeminiModel : config.aiOpenaiModel;
}

export async function selectProvider(
  store: Repository,
  config: AppConfig,
  managed: AiProvider,
  principal: Principal,
  input: { billing?: AiBilling; model: string; maxCost?: number },
  factory: ProviderFactory = (provider, key) =>
    configuredProvider(config, provider, key),
) {
  const billing = input.billing ?? {
    kind: 'managed',
    provider: config.aiProvider,
  };
  if (billing.kind === 'managed' && billing.provider !== config.aiProvider)
    throw unavailable();
  const base = baseModel(config, billing.provider);
  if (base === '') throw unavailable();
  const model = input.model === 'default' ? base : input.model;
  const isBase = model === base;
  const cost =
    config.aiModelCostCeilings[`${billing.provider}:${model}`] ??
    (isBase ? config.aiRequestCostCeiling : undefined);
  if (cost === undefined || cost <= 0)
    throw isBase
      ? unavailable()
      : invalidRequest(
          'This analysis model is not enabled by your organisation.',
        );
  if (!isBase && input.maxCost === undefined)
    throw invalidRequest(
      'Approve a maximum cost before escalating this analysis model.',
    );
  if (input.maxCost !== undefined && input.maxCost < cost)
    throw quotaExceeded(
      "The approved maximum cost is below this model's configured attempt ceiling.",
      { ceiling: cost },
    );
  if (billing.kind === 'managed')
    return {
      kind: billing.kind,
      model,
      cost,
      provider: managed,
      providerName: billing.provider,
      accountId: `managed:${billing.provider}:${createHash('sha256').update(config.aiProviderKey).digest('hex')}`,
    };
  const credential = await store.aiCredential(
    principal.userId,
    billing.provider,
  );
  if (credential === undefined) throw unavailable();
  const key = decryptCredential(config, credential);
  return {
    kind: billing.kind,
    model,
    cost,
    provider: factory(billing.provider, key),
    providerName: billing.provider,
    credentialRevision: credential.revision,
    accountId: `personal:${billing.provider}:${principal.userId}:${credential.revision}`,
  };
}

export async function providerCatalogue(
  store: Repository,
  config: AppConfig,
  principal: Principal,
) {
  const providers = [];
  for (const provider of ['gemini', 'openai'] as const) {
    const model = baseModel(config, provider);
    if (model === '') continue;
    const status = await credentialStatus(store, principal, provider);
    const models = [
      model,
      ...Object.keys(config.aiModelCostCeilings)
        .filter((entry) => entry.startsWith(`${provider}:`))
        .map((entry) => entry.slice(provider.length + 1))
        .filter((entry) => entry !== model),
    ];
    const modelCostCeilings = Object.fromEntries(
      models.map((name) => [
        name,
        config.aiModelCostCeilings[`${provider}:${name}`] ??
          config.aiRequestCostCeiling,
      ]),
    );
    providers.push({
      provider,
      model,
      models,
      modelCostCeilings,
      requestCostCeiling:
        config.aiModelCostCeilings[`${provider}:${model}`] ??
        config.aiRequestCostCeiling,
      currency: 'configured',
      managed: provider === config.aiProvider && config.aiProviderKey !== '',
      personalConfigured: status.configured,
    });
  }
  return { providers };
}

export async function aiAvailable(
  store: Repository,
  config: AppConfig,
  principal: Principal,
): Promise<boolean> {
  if (!can(principal, 'aiProxy')) return false;
  const catalogue = await providerCatalogue(store, config, principal);
  return catalogue.providers.some(
    (entry) =>
      entry.requestCostCeiling > 0 &&
      (entry.managed ||
        (entry.personalConfigured && config.aiCredentialEncryptionKey !== '')),
  );
}
