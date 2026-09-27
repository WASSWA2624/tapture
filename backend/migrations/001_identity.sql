-- Identity: organisations, users, devices. No project content.
BEGIN;

CREATE TABLE organisations (
  id text PRIMARY KEY,
  name text NOT NULL,
  self_register boolean NOT NULL DEFAULT false,
  retention_days integer NOT NULL CHECK (retention_days BETWEEN 1 AND 90),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id text PRIMARY KEY,
  organisation_id text NOT NULL REFERENCES organisations (id),
  email text NOT NULL,
  password_hash text NOT NULL,
  role text NOT NULL,
  status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organisation_id, email)
);

-- Login and invite lookup by address inside one organisation.
CREATE INDEX users_org_email_idx ON users (organisation_id, email);

CREATE TABLE devices (
  id text PRIMARY KEY,
  user_id text NOT NULL REFERENCES users (id),
  enrolled_at timestamptz NOT NULL,
  last_seen_at timestamptz NOT NULL,
  revoked boolean NOT NULL DEFAULT false
);

-- Devices belonging to one account, for the device list.
CREATE INDEX devices_user_idx ON devices (user_id);

CREATE TABLE refresh_families (
  id text PRIMARY KEY,
  user_id text NOT NULL REFERENCES users (id),
  device_id text NOT NULL REFERENCES devices (id),
  token_hash text NOT NULL,
  rotated boolean NOT NULL DEFAULT false,
  revoked boolean NOT NULL DEFAULT false,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE invitations (
  token_hash text PRIMARY KEY,
  user_id text NOT NULL REFERENCES users (id),
  used boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL
);

COMMIT;
