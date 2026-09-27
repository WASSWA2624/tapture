-- Append-only audit and security events.
BEGIN;

CREATE TABLE audit_events (
  id text PRIMARY KEY,
  at timestamptz NOT NULL,
  actor_id text NOT NULL,
  action text NOT NULL,
  target text NOT NULL,
  before jsonb,
  after jsonb
);

-- Investigation reads events in time order.
CREATE INDEX audit_events_at_idx ON audit_events (at);

CREATE TABLE security_events (
  id text PRIMARY KEY,
  at timestamptz NOT NULL,
  actor_id text NOT NULL,
  action text NOT NULL,
  target text NOT NULL,
  before jsonb,
  after jsonb
);

CREATE INDEX security_events_at_idx ON security_events (at);

CREATE OR REPLACE FUNCTION forbid_audit_mutation() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit rows are append-only';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_events_no_update
  BEFORE UPDATE OR DELETE ON audit_events
  FOR EACH ROW EXECUTE FUNCTION forbid_audit_mutation();

CREATE TRIGGER security_events_no_update
  BEFORE UPDATE OR DELETE ON security_events
  FOR EACH ROW EXECUTE FUNCTION forbid_audit_mutation();

CREATE TABLE ai_usage (
  id text PRIMARY KEY,
  project_id text NOT NULL,
  user_id text NOT NULL,
  model text NOT NULL,
  byte_size integer NOT NULL,
  duration_ms integer NOT NULL,
  outcome text NOT NULL,
  cost numeric NOT NULL,
  at timestamptz NOT NULL
);

COMMIT;
