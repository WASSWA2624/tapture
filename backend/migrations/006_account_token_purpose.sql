-- Invitations and password resets are distinct capabilities. Legacy tokens
-- remain invitations; old reset links must be reissued, never reinterpreted.
BEGIN;
ALTER TABLE invitations ADD COLUMN purpose text NOT NULL DEFAULT 'invitation'
  CHECK (purpose IN ('invitation', 'password_reset'));
COMMIT;
