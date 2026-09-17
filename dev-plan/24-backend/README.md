# 24 — The minimal backend

The minimal backend of specification Part XI. It is **required**: accounts, authentication, roles, AI functionality and provider-key custody — the five things a single device cannot supply for itself, and nothing more. The change relay (§72) is the one optional capability inside this phase; every other task here is part of the MVP. Required to exist, never required to be reachable (§70.4).

Tasks 245–270 (26). Each file is a standalone implementation prompt.

- [ ] [245 — Initialise the backend project and its gate](245-be-project-init.md)
- [ ] [246 — Configuration loading and validation](246-be-config.md)
- [ ] [247 — Structured logger, typed errors and the error envelope](247-be-logger.md)
- [ ] [248 — HTTP server, middleware chain and limits](248-be-http-server.md)
- [ ] [249 — Database connection, pooling and migrations](249-be-db-connection.md)
- [ ] [250 — Schema: organisations, users, devices, projects and members](250-be-schema-identity.md)
- [ ] [251 — Schema: relay packages, acknowledgements, version vectors and audit](251-be-schema-relay.md)
- [ ] [252 — Repository base and transactions](252-be-repositories.md)
- [ ] [253 — Password hashing and the account lifecycle](253-be-auth-passwords.md)
- [ ] [254 — Login with rate limiting and lockout](254-be-auth-login.md)
- [ ] [255 — Tokens, authentication middleware and device enrolment](255-be-auth-tokens.md)
- [ ] [256 — Role matrix and permission checks](256-be-permissions.md)
- [ ] [257 — Organisation user endpoints](257-be-users-api.md)
- [ ] [258 — Project and membership endpoints](258-be-projects-api.md)
- [ ] [259 — Relay: accept, list and download packages](259-be-relay-push.md)
- [ ] [260 — Relay: acknowledge, delete and report state](260-be-relay-ack.md)
- [ ] [261 — Relay purge job and storage ceilings](261-be-retention-job.md)
- [ ] [262 — AI provider abstraction and key custody](262-be-ai-provider.md)
- [ ] [263 — AI proxy endpoints, quotas and resilience](263-be-ai-proxy.md)
- [ ] [264 — Audit, security events and metrics](264-be-audit-service.md)
- [ ] [265 — OpenAPI specification and contract tests](265-be-openapi.md)
- [ ] [266 — Export, destroy, deploy and the pipeline](266-be-admin-commands.md)
- [ ] [267 — App: backend connection, sign in and enrolment](267-fe-backend-config.md)
- [ ] [268 — App: role affordances, cached grants and offline authority](268-fe-role-affordances.md)
- [ ] [269 — App: change relay client and controls](269-fe-relay-client.md)
- [ ] [270 — App: route AI through the backend](270-fe-ai-proxy-client.md)
