-- Projects and membership. Names and relay settings only; no records.
BEGIN;

CREATE TABLE projects (
  id text PRIMARY KEY,
  organisation_id text NOT NULL REFERENCES organisations (id),
  name text NOT NULL,
  relay_enabled boolean NOT NULL DEFAULT false,
  never_relay boolean NOT NULL DEFAULT false,
  retention_days integer NOT NULL CHECK (retention_days BETWEEN 1 AND 90),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Projects visible to one organisation.
CREATE INDEX projects_org_idx ON projects (organisation_id);

CREATE TABLE project_members (
  project_id text NOT NULL REFERENCES projects (id),
  user_id text NOT NULL REFERENCES users (id),
  context_scope text,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (project_id, user_id)
);

-- Memberships for one person, used by GET /auth/me.
CREATE INDEX project_members_user_idx ON project_members (user_id);

COMMIT;
