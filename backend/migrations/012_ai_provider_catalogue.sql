-- W16 keeps existing ciphertext and replay metadata byte-for-byte; only IDs widen.
BEGIN;
ALTER TABLE ai_credentials DROP CONSTRAINT ai_credentials_provider_check;
ALTER TABLE ai_credentials ADD CONSTRAINT ai_credentials_provider_check
  CHECK (provider ~ '^[a-z][a-z0-9-]{0,63}$');
COMMIT;
