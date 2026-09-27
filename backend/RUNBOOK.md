# Backend runbook

One container serves one organisation. The device remains the store of record. This server holds accounts, membership and optional relay metadata. It does not hold project content.

## Deploy

Set `DATABASE_URL` and `TOKEN_SECRET` in the environment. Do not bake them into the image. Apply migrations with an explicit command before serving traffic:

```bash
npm run admin -- migrate
```

The process does not migrate on boot. Readiness stays failed until the pool connects and the secret store is present.

## Upgrade

Apply the next numbered migration forward only. A changed checksum or an out-of-order file refuses to run. Accounts, memberships and audit rows from the previous schema stay in place.

## Rotate a key

Replace `TOKEN_SECRET` and restart. Existing access tokens stop verifying. Users sign in again. Provider keys live in the key holder, not in the database and not in the client.

## Change retention

Set `RETENTION_DAYS` between 1 and 90. A value above 90 refuses to boot. Project retention cannot exceed the organisation maximum or 90 days.

## A purge failed

Read the purge report: `deleted`, `bytesReclaimed`, `oldestAgeSeconds`, `failures`. A non-zero `failures` means rows were left behind. Fix the cause and run the job again. Do not delete audit rows.

## Restore

Restore accounts, devices, memberships, roles, audit and package metadata. Projects are not included in a backup. Captured records stay on the devices. An export says so in its README.

## Unexpected growth

If storage grows while purge stays flat, retention is broken. Investigate before adding disk or another instance.
