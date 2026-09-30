-- Preserve the legacy user/device revocation scope until legacy tokens expire.
BEGIN;
ALTER TABLE refresh_families ADD COLUMN family_id text;
UPDATE refresh_families SET family_id = 'legacy:' || user_id || ':' || device_id;
ALTER TABLE refresh_families ALTER COLUMN family_id SET NOT NULL;
-- Reuse and sign-out revoke only the related chain.
CREATE INDEX refresh_families_family_idx ON refresh_families (family_id);
-- Bounded refresh cleanup scans by expiry.
CREATE INDEX refresh_families_expiry_idx ON refresh_families (expires_at);
-- Bounded token cleanup scans by expiry.
CREATE INDEX invitations_expiry_idx ON invitations (expires_at);
-- Authentication compares legacy and normalized email addresses consistently.
CREATE INDEX users_org_lower_email_idx ON users (organisation_id,lower(email));
COMMIT;
