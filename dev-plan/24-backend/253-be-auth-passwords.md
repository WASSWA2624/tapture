# 253 — Password hashing and the account lifecycle

**Phase** 24 · The minimal backend  |  **Depends on** [252](252-be-repositories.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Argon2id password storage, and the four account endpoints §71.1 names other than sign-in: administrator-created
accounts, invitation acceptance, password change and password reset. §74.2 is the whole API (BE-API-01), so these are
built here rather than left implied.

## Files

- `backend/src/services/auth/password.ts` (new — hashing, change and reset)
- `backend/src/services/auth/register.ts` (new)
- `backend/src/routes/auth/register.ts` (new)
- `backend/src/routes/auth/password.ts` (new)
- `backend/test/services/password.test.ts` (new)
- `backend/test/routes/auth_account.test.ts` (new)

## Contract

```ts
hashPassword(plain: string): Promise<string>;  verifyPassword(plain: string, hash: string): Promise<boolean>

POST /api/v1/auth/register   POST /api/v1/auth/change-password   POST /api/v1/auth/reset
```

## Steps

1. Argon2id with parameters documented beside the code and read from configuration, so raising them later is a value
   change; verification tolerates a hash written with older parameters and rehashes on next successful use.
2. An administrator creates an account; the invitee accepts by setting a password against a single-use invitation
   token. Self-service registration stays disabled unless the organisation enables it.
3. Change-password requires the current password, re-hashes, and invalidates every refresh-token family for that user
   so an old session cannot outlive the change.
4. Reset issues a single-use, short-lived, rate-limited token and answers identically whether or not the address is
   known, so the endpoint is not an account oracle (BE-SEC-07, BE-API-09).
5. Each of these writes an administrative audit entry (BE-OBS-07).

## Constraints

- A memory-hard hash only; never a fast hash, never a reversible scheme, and never a hash in a log or a response
  (BE-SEC-02).
- Email uniqueness per organisation is enforced without revealing whether an address exists.

## Definition of done

- [ ] A stored hash is irreversible and appears in no log, response or error path.
- [ ] Self-service registration is off unless the organisation enables it, and neither register nor reset reveals
      whether an address exists.
- [ ] A changed or reset password invalidates every existing refresh-token family for that user.
- [ ] Tests: unit tests for hashing, verification and a parameter change; route tests for success, duplicate address,
      registration disabled, wrong current password, expired reset token and replayed reset token.
