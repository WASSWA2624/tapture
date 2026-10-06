import type { AiReceipt, CredentialRow, ProviderName } from '../domain/ai.js';
import type { Sql } from './sql.js';
import { conflict } from '../domain/errors.js';

export function aiRepository(sql: Sql) {
  return {
    aiCredential: async (userId: string, provider: ProviderName) =>
      (
        await sql.rows<CredentialRow>(
          'SELECT user_id AS "userId",provider,revision,encrypted_key AS "encryptedKey",created_at AS "createdAt" FROM ai_credentials WHERE user_id=$1 AND provider=$2',
          [userId, provider],
        )
      )[0],
    saveAiCredential: (row: CredentialRow) =>
      sql.write(
        'INSERT INTO ai_credentials(user_id,provider,revision,encrypted_key,created_at) VALUES($1,$2,$3,$4,$5) ON CONFLICT(user_id,provider) DO UPDATE SET revision=$3,encrypted_key=$4,created_at=$5',
        [
          row.userId,
          row.provider,
          row.revision,
          row.encryptedKey,
          row.createdAt,
        ],
      ),
    deleteAiCredential: (userId: string, provider: ProviderName) =>
      sql.write('DELETE FROM ai_credentials WHERE user_id=$1 AND provider=$2', [
        userId,
        provider,
      ]),
    aiReceipt: async (key: string) =>
      (
        await sql.rows<AiReceipt>(
          'SELECT idempotency_key AS "idempotencyKey",binding_hash AS "bindingHash",user_id AS "userId",device_id AS "deviceId",project_id AS "projectId",usage_id AS "usageId",status,created_at AS "createdAt" FROM ai_receipts WHERE idempotency_key=$1',
          [key],
        )
      )[0],
    saveAiReceipt: async (row: AiReceipt) => {
      const saved = await sql.rows<{ idempotencyKey: string }>(
        'INSERT INTO ai_receipts(idempotency_key,binding_hash,user_id,device_id,project_id,usage_id,status,created_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT(idempotency_key) DO UPDATE SET status=$7 WHERE ai_receipts.binding_hash=$2 AND ai_receipts.user_id=$3 AND ai_receipts.device_id=$4 AND ai_receipts.project_id=$5 AND ai_receipts.usage_id=$6 AND $7 <> \'running\' RETURNING idempotency_key AS "idempotencyKey"',
        [
          row.idempotencyKey,
          row.bindingHash,
          row.userId,
          row.deviceId,
          row.projectId,
          row.usageId,
          row.status,
          row.createdAt,
        ],
      );
      if (saved.length !== 1)
        throw conflict('This analysis attempt already exists.');
    },
  };
}
