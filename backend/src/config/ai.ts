import type { ProviderDefinition, ProviderName } from '../domain/ai.js';
import { parseProviderCatalogue, providerUrl } from './provider-catalogue.js';

export interface AiConfiguration {
  readonly aiProviderCatalogue: readonly ProviderDefinition[];
  readonly aiProvider: ProviderName;
  readonly aiGeminiModel: string;
  readonly aiOpenaiModel: string;
  readonly aiOpenaiUrl: string;
  readonly aiCredentialEncryptionKey: string;
  readonly aiModelCostCeilings: Readonly<Record<string, number>>;
  readonly aiMaxOutputTokens: number;
}

function model(value: string, name: string): string {
  if (value !== '' && !/^[A-Za-z0-9._-]+$/.test(value))
    throw new Error(`${name} must be a model identifier.`);
  return value;
}

export function parseAiConfiguration(
  env: NodeJS.ProcessEnv,
  managedModel: string,
): AiConfiguration {
  const aiProvider = env['AI_PROVIDER'] ?? 'gemini';
  if (aiProvider !== 'gemini' && aiProvider !== 'openai')
    throw new Error('AI_PROVIDER must be gemini or openai.');
  const aiCredentialEncryptionKey = env['AI_CREDENTIAL_ENCRYPTION_KEY'] ?? '';
  if (
    aiCredentialEncryptionKey !== '' &&
    !/^[a-fA-F0-9]{64}$/.test(aiCredentialEncryptionKey)
  )
    throw new Error(
      'AI_CREDENTIAL_ENCRYPTION_KEY must contain 64 hexadecimal characters.',
    );
  const aiOpenaiUrl = providerUrl(
    env['AI_OPENAI_URL'] ?? 'https://api.openai.com/v1',
    'AI_OPENAI_URL',
  );
  const aiMaxOutputTokens = Number(env['AI_MAX_OUTPUT_TOKENS'] ?? '4096');
  if (
    !Number.isSafeInteger(aiMaxOutputTokens) ||
    aiMaxOutputTokens < 1 ||
    aiMaxOutputTokens > 32768
  )
    throw new Error('AI_MAX_OUTPUT_TOKENS must be from 1 to 32768.');
  let costs: unknown;
  try {
    costs = JSON.parse(env['AI_MODEL_COST_CEILINGS'] ?? '{}');
  } catch {
    throw new Error('AI_MODEL_COST_CEILINGS must be a JSON object.');
  }
  if (typeof costs !== 'object' || costs === null || Array.isArray(costs))
    throw new Error('AI_MODEL_COST_CEILINGS must be a JSON object.');
  const aiModelCostCeilings: Record<string, number> = {};
  for (const [name, value] of Object.entries(costs)) {
    if (
      !/^(gemini|openai):[A-Za-z0-9._-]+$/.test(name) ||
      typeof value !== 'number' ||
      !Number.isFinite(value) ||
      value <= 0
    )
      throw new Error(
        'AI_MODEL_COST_CEILINGS requires provider:model keys and positive finite attempt ceilings.',
      );
    aiModelCostCeilings[name] = value;
  }
  return {
    aiProviderCatalogue: parseProviderCatalogue(env['AI_PROVIDER_CATALOGUE']),
    aiProvider,
    aiGeminiModel: model(
      env['AI_GEMINI_MODEL'] ||
        (aiProvider === 'gemini' && managedModel !== 'default'
          ? managedModel
          : ''),
      'AI_GEMINI_MODEL',
    ),
    aiOpenaiModel: model(
      env['AI_OPENAI_MODEL'] ||
        (aiProvider === 'openai' && managedModel !== 'default'
          ? managedModel
          : ''),
      'AI_OPENAI_MODEL',
    ),
    aiOpenaiUrl: aiOpenaiUrl.replace(/\/$/, ''),
    aiCredentialEncryptionKey,
    aiModelCostCeilings,
    aiMaxOutputTokens,
  };
}
