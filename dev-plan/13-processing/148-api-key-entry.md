# 148 — Device-held API key: the permitted exception

**Phase** 13 · Processing  |  **Depends on** [027](../02-foundation/027-secure-storage-service.md), [035](../03-design-system/035-app-text-field.md), [147](147-provider-registry.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Let a key be entered and stored safely on the device, masked after entry — as the **exception** A30.2 permits, not
the norm. Custody belongs to the backend (A73.1); this screen exists for the lone operator an administrator has
allowed to work with the server out of reach. From the same screen, one **Test connection** call proves the key and
endpoint, or names precisely which of the two failed.

## Files

- `frontend/lib/features/settings/presentation/api_key_screen.dart` (new)
- `frontend/lib/features/settings/presentation/provider_test_action.dart` (new)

## Steps

1. Store only in platform secure storage; never in the database, a log, an export or a bundle.
2. State on the screen, in one line, that the key lives on this device only and that the usual arrangement is for the
   organisation's backend to hold it.
3. Offer removal in one action that also clears the selection.
4. Test connection sends the smallest possible request through the registry in `frontend/lib/core/ai/`; this action
   never imports an HTTP client itself, and reports success, authentication failure and network failure distinctly.

## Constraints

- The key goes to secure storage and nowhere else (FE-SEC-01), and device custody stays framed as the permitted
  exception (FE-SEC-02).
- The entry field is `AppTextField` from task 035, obscured after save (FE-CONS-01).

## Definition of done

- [ ] A key is unreadable after saving and removable in one action.
- [ ] The screen never presents device custody as the recommended arrangement.
- [ ] Test connection tells authentication failure and network failure apart.
- [ ] Tests: test asserting the key never appears in the database or an export; widget test of
      `provider_test_action.dart`, including its empty and failure states.
