# 255 — Tokens, authentication middleware and device enrolment

**Phase** 24 · The minimal backend  |  **Depends on** [254](254-be-auth-login.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The session mechanics: short-lived access tokens and rotating refresh tokens bound to an enrolled device, the refresh
and sign-out endpoints that spend them, the middleware that turns an access token into a principal, and the enrolment
that binds a device identifier to an account in the first place — which is what makes server-side roles meaningful.

## Files

- `backend/src/services/auth/tokens.ts` (new)
- `backend/src/routes/auth/session.ts` (new)
- `backend/src/middleware/authenticate.ts` (new)
- `backend/src/routes/devices.ts` (new)
- `backend/test/services/tokens.test.ts` (new)
- `backend/test/middleware/authenticate.test.ts` (new)
- `backend/test/routes/devices.test.ts` (new)

## Contract

```ts
issueTokens(userId, deviceId): Promise<TokenPair>;  rotate(refresh: string): Promise<TokenPair>
revoke(refresh: string): Promise<void>

POST /api/v1/auth/refresh   POST /api/v1/auth/logout
POST /api/v1/devices        GET /api/v1/devices        DELETE /api/v1/devices/:id
```

## Steps

1. Bind every refresh token to a device identifier and a family; rotation issues the next token and retires the
   previous one.
2. Detect refresh reuse, invalidate the whole family and log a security event.
3. Sign-out revokes the presenting device's family and is idempotent: signing out twice, or with an already-expired
   token, succeeds silently rather than erroring (BE-API-07). It is a server-side revocation only and never reaches the
   device's project data, which stays exactly where it is (§70.2).
4. The middleware verifies the access token, loads the principal with its organisation, role and enrolled device, and
   attaches it to the request context; expired, malformed and missing tokens all give 401 in the standard envelope.
5. Enrolment records the device identifier, model, application version and enrolment time against the account; an
   administrator may list and revoke devices, and a revoked device can neither refresh nor reach the relay.

## Constraints

- Access tokens are short-lived; refresh tokens rotate and are device-bound; reuse invalidates the family and is logged
  as a security event (BE-SEC-03).
- This is security-relevant surface: it needs a second reader (BE-SEC-11, BE-FLOW-04).

## Definition of done

- [ ] A stolen refresh token cannot be replayed after rotation; reuse kills the family and records a security event.
- [ ] Signing out twice succeeds both times and revokes exactly one family.
- [ ] A revoked device can neither refresh a token nor reach the relay.
- [ ] Tests: unit tests for rotation, expiry, reuse detection and repeated sign-out; middleware tests for valid,
      expired, malformed and missing access tokens; route tests for enrol, list and revoke.
