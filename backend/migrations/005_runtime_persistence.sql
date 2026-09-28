-- Runtime state that previously existed only in the test store.
BEGIN;
CREATE TABLE login_lockouts (
  key text PRIMARY KEY,
  failures integer NOT NULL CHECK (failures >= 0),
  locked_until timestamptz
);

-- Opaque, transient ciphertext only. Exclude this table from account backups.
-- Cascading removal makes acknowledgement/expiry atomic with byte deletion.
CREATE TABLE relay_blobs (
  package_id text PRIMARY KEY REFERENCES relay_packages(id) ON DELETE CASCADE,
  storage_ref text UNIQUE NOT NULL,
  ciphertext bytea NOT NULL
);
ALTER TABLE relay_acknowledgements DROP CONSTRAINT relay_acknowledgements_package_id_fkey;
ALTER TABLE relay_acknowledgements ADD CONSTRAINT relay_acknowledgements_package_id_fkey
  FOREIGN KEY (package_id) REFERENCES relay_packages(id) ON DELETE CASCADE;
-- Token lookup must select exactly one family.
CREATE UNIQUE INDEX refresh_families_token_hash_idx ON refresh_families(token_hash);
-- Daily quota queries for each project or user.
CREATE INDEX ai_usage_project_at_idx ON ai_usage(project_id,at);
CREATE INDEX ai_usage_user_at_idx ON ai_usage(user_id,at);
COMMIT;
