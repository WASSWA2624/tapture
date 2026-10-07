import { createHash } from 'node:crypto';
import type { AppConfig } from '../../config/schema.js';
import type { AiBilling, ProviderName } from '../../domain/ai.js';
import {
  invalidRequest,
  quotaExceeded,
  unavailable,
} from '../../domain/errors.js';
import { can, type Principal } from '../../domain/permissions.js';
import { notFound } from '../../domain/errors.js';
import type { Repository } from '../../repositories/repository.js';
import { credentialStatus, decryptCredential } from './credentials.js';
import { httpProvider } from './http_provider.js';
import { openaiProvider } from './openai-provider.js';
import type { AiProvider } from './provider.js';
import {
  providerDefinition,
  providerDefinitions,
  providerFingerprint,
} from './catalogue.js';

export type ProviderFactory = (
  provider: ProviderName,
  key: string,
) => AiProvider;

export function configuredProvider(
  config: AppConfig,
  provider: ProviderName,
  key: string,
): AiProvider {
  const definition = providerDefinition(config, provider);
  return definition.protocol === 'gemini-generate-content'
    ? httpProvider(config, fetch, key, definition)
    : openaiProvider(config, key, fetch, definition);
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
  const definition = providerDefinition(config, billing.provider);
  const keyless = definition.authMode === 'none';
  if (
    (keyless && billing.kind !== 'managed') ||
    (!keyless &&
      billing.kind === 'managed' &&
      billing.provider !== config.aiProvider)
  )
    throw unavailable();
  const base = definition.model;
  if (base === '') throw unavailable();
  const model = input.model === 'default' ? base : input.model;
  const isBase = model === base;
  const cost = definition.modelCostCeilings[model];
  if (!definition.models.includes(model) || cost === undefined || cost <= 0)
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
  const fingerprint = providerFingerprint(definition);
  const legacy =
    !keyless &&
    (billing.provider === 'gemini' || billing.provider === 'openai');
  if (billing.kind === 'managed') {
    const previousAccountId = `managed:${billing.provider}:${createHash(
      'sha256',
    )
      .update(keyless ? '' : config.aiProviderKey)
      .digest('hex')}`;
    return {
      kind: billing.kind,
      model,
      cost,
      provider: keyless ? factory(billing.provider, '') : managed,
      providerName: billing.provider,
      operations: definition.operations,
      accountId: `${previousAccountId}:configuration:${fingerprint}`,
      ...(legacy ? { legacyAccountId: previousAccountId } : {}),
    };
  }
  const credential = await store.aiCredential(
    principal.userId,
    billing.provider,
  );
  if (credential === undefined) throw unavailable();
  const key = decryptCredential(config, credential);
  const previousAccountId = `personal:${billing.provider}:${principal.userId}:${credential.revision}`;
  return {
    kind: billing.kind,
    model,
    cost,
    provider: factory(billing.provider, key),
    providerName: billing.provider,
    operations: definition.operations,
    credentialRevision: credential.revision,
    accountId: `${previousAccountId}:configuration:${fingerprint}`,
    ...(legacy ? { legacyAccountId: previousAccountId } : {}),
  };
}

export async function providerCatalogue(
  store: Repository,
  config: AppConfig,
  principal: Principal,
) {
  if (!can(principal, 'aiProxy')) throw notFound();
  const providers = [];
  for (const definition of providerDefinitions(config)) {
    const {
      id: provider,
      model,
      models,
      modelCostCeilings,
      authMode,
      protocol,
      label,
      operations,
    } = definition;
    if (model === '') continue;
    const status =
      authMode === 'none'
        ? { configured: false }
        : await credentialStatus(store, principal, provider, config);
    providers.push({
      provider,
      label,
      protocol,
      authMode,
      operations,
      model,
      models,
      modelCostCeilings,
      requestCostCeiling: modelCostCeilings[model] ?? 0,
      currency: 'configured',
      managed:
        authMode === 'none' ||
        (provider === config.aiProvider && config.aiProviderKey !== ''),
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
