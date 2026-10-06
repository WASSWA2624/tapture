-- Personal API credentials are ciphertext; the envelope key stays in the secret store.
BEGIN;
CREATE TABLE ai_credentials (
  user_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('gemini','openai')),
  revision text NOT NULL,
  encrypted_key text NOT NULL,
  created_at timestamptz NOT NULL,
  PRIMARY KEY(user_id,provider)
);

ALTER TABLE ai_usage ADD COLUMN provider text;
ALTER TABLE ai_usage ADD COLUMN billing_kind text;
ALTER TABLE ai_usage ADD COLUMN input_tokens integer CHECK(input_tokens >= 0);
ALTER TABLE ai_usage ADD COLUMN output_tokens integer CHECK(output_tokens >= 0);
ALTER TABLE ai_usage ADD COLUMN total_tokens integer CHECK(total_tokens >= 0);

-- No payload or generated output. Keep these tombstones for replay safety until
-- the deployment is destroyed; expiring a receipt could charge an old retry twice.
CREATE TABLE ai_receipts (
  idempotency_key text PRIMARY KEY CHECK(idempotency_key ~ '^[a-f0-9]{64}$'),
  binding_hash text NOT NULL CHECK(binding_hash ~ '^[a-f0-9]{64}$'),
  user_id text NOT NULL REFERENCES users(id),
  device_id text NOT NULL REFERENCES devices(id),
  project_id text NOT NULL REFERENCES projects(id),
  usage_id text NOT NULL REFERENCES ai_usage(id),
  status text NOT NULL CHECK(status IN ('running','completed','uncertain')),
  created_at timestamptz NOT NULL
);
COMMIT;
