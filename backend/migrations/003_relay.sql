-- Relay metadata. Package bytes live in the blob store, not in this table.
BEGIN;

CREATE TABLE relay_packages (
  id text PRIMARY KEY,
  project_id text NOT NULL REFERENCES projects (id),
  author_device_id text NOT NULL,
  byte_size integer NOT NULL,
  created_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL,
  storage_ref text NOT NULL
);

-- Purge scans by expiry.
CREATE INDEX relay_packages_expires_idx ON relay_packages (expires_at);

-- Download lists one project's waiting packages.
CREATE INDEX relay_packages_project_idx ON relay_packages (project_id);

CREATE TABLE relay_acknowledgements (
  package_id text NOT NULL REFERENCES relay_packages (id),
  device_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (package_id, device_id)
);

CREATE TABLE relay_vectors (
  project_id text NOT NULL REFERENCES projects (id),
  device_id text NOT NULL,
  counter integer NOT NULL,
  PRIMARY KEY (project_id, device_id)
);

CREATE TABLE idempotency_keys (
  key text PRIMARY KEY,
  status integer NOT NULL,
  body jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL
);

COMMIT;
