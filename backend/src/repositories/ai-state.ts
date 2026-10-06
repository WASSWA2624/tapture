import type { AiReceipt, CredentialRow, TokenUsage } from '../domain/ai.js';

export interface AiState {
  credentials: CredentialRow[];
  receipts: AiReceipt[];
}

export type UsageMetadata = TokenUsage & {
  readonly provider?: string;
  readonly billingKind?: string;
};
