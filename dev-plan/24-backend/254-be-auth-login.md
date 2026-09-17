# 254 — Login with rate limiting and lockout

**Phase** 24 · The minimal backend  |  **Depends on** [253](253-be-auth-passwords.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Sign-in: verify the credential, apply per-address and per-account limits, lock the account after the configured run of
failures, and record a security event for each failure and for the lockout itself.

## Files

- `backend/src/routes/auth/login.ts` (new)
- `backend/src/services/auth/login.ts` (new)
- `backend/test/routes/auth_login.test.ts` (new)

## Contract

```ts
POST /api/v1/auth/login   // { email, password, deviceId } -> TokenPair
```

## Steps

1. Answer a wrong password and an unknown address identically, in the same time envelope, with the same code.
2. Count failures per address and per account against the thresholds in configuration; on lockout, refuse until the
   window elapses or an administrator clears it, and say so without naming which condition applied.
3. Clear the failure count on a successful sign-in.

## Constraints

- Lockout and its security event are required, not advisory (BE-SEC-07); the per-address ceiling comes from the
  middleware limiter already in the chain and is not re-implemented here.
- The submitted password never reaches a log line or an audit row (BE-OBS-02).

## Definition of done

- [ ] Repeated failures lock the account and record a security event naming actor, address and time.
- [ ] A wrong password and an unknown address are indistinguishable to the caller.
- [ ] Tests: route tests for success, wrong password, unknown address, lockout, refusal while locked and the reset of
      the counter after success.
