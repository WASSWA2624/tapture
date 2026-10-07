/** Administrator-configured identifier, validated at configuration and HTTP boundaries. */
export type ProviderName = string;
export type ProviderProtocol = 'gemini-generate-content' | 'openai-responses';
export type ProviderAuthMode = 'required' | 'none';
export type AiOperation = 'ocr' | 'extract' | 'refine' | 'transcribe';

export interface ProviderDefinition {
  readonly id: ProviderName;
  readonly label: string;
  readonly protocol: ProviderProtocol;
  readonly baseUrl: string;
  readonly authMode: ProviderAuthMode;
  readonly models: readonly string[];
  readonly operations: readonly AiOperation[];
  readonly model: string;
  readonly currency: 'configured';
  readonly modelCostCeilings: Readonly<Record<string, number>>;
}
export type BillingKind = 'managed' | 'personal';

export interface AiBilling {
  readonly kind: BillingKind;
  readonly provider: ProviderName;
}

export interface ProcessingIdentity {
  readonly version: 1;
  readonly projectRevision: string;
  readonly recordId: string;
  readonly requestHash: string;
  readonly idempotencyKey: string;
}

export interface TokenUsage {
  readonly inputTokens?: number;
  readonly outputTokens?: number;
  readonly totalTokens?: number;
}

export interface CredentialRow {
  readonly userId: string;
  readonly provider: ProviderName;
  readonly revision: string;
  readonly encryptedKey: string;
  readonly createdAt: string;
}

/** Permanent metadata tombstone prevents a lost reply from causing a second bill. */
export interface AiReceipt {
  readonly idempotencyKey: string;
  readonly bindingHash: string;
  readonly userId: string;
  readonly deviceId: string;
  readonly projectId: string;
  readonly usageId: string;
  readonly status: 'running' | 'completed' | 'uncertain';
  readonly createdAt: string;
}
