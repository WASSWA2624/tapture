-- Lockout state expires independently of durable account/audit metadata.
BEGIN;
ALTER TABLE login_lockouts ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE login_lockouts ADD COLUMN expires_at timestamptz NOT NULL DEFAULT now() + interval '1 day';
-- Scheduled cleanup scans the bounded authentication and replay windows.
CREATE INDEX login_lockouts_expiry_idx ON login_lockouts (expires_at);
CREATE INDEX idempotency_keys_expiry_idx ON idempotency_keys (expires_at);
-- Acknowledgements share their package's expiry and cascade on package removal.
-- Explicit expiry makes all in-flight state inspectable with the same clock.
ALTER TABLE relay_acknowledgements ADD COLUMN expires_at timestamptz;
UPDATE relay_acknowledgements a SET expires_at = p.expires_at FROM relay_packages p WHERE p.id = a.package_id;
ALTER TABLE relay_acknowledgements ALTER COLUMN expires_at SET NOT NULL;
COMMIT;
