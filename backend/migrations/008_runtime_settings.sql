-- Digests detect changes; this table contains no usable credentials.
BEGIN;
CREATE TABLE runtime_settings (
  name text PRIMARY KEY,
  fingerprint text NOT NULL,
  metadata jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
COMMIT;
