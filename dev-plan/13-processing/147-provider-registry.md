# 147 — Provider registry, selection and the egress preview

**Phase** 13 · Processing  |  **Depends on** [029](../02-foundation/029-ai-service-interface.md), [041](../03-design-system/041-app-dialog-service.md), [078](../07-account-and-settings/078-settings-store.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every available implementation registered and chosen per project and per operation behind one interface, with the
organisation's backend proxy a first-class entry that holds no key, and a preview shown before the first online call
of a session stating exactly what will leave the device.

## Files

- `frontend/lib/core/ai/provider_registry.dart` (new)
- `frontend/lib/features/processing/presentation/egress_preview_dialog.dart` (new)

## Steps

1. Resolve selection per project and per operation through the interface of task 029; no caller learns which
   implementation answered.
2. A registry entry carries where its key lives, never the key itself. The default entry — the backend proxy of
   Part XI — holds none, because custody belongs to the backend (A30.2, A73.1).
3. The preview states image count, approximate payload size, and that captions and field names are included.
4. Declining leaves the session offline: the queue is untouched and every job stays claimable.

## Constraints

- HTTP imports stay inside `core/ai/`; the dialog asks the registry what would be sent and never builds a request
  itself (FE-SEC-03).
- The preview is raised through the dialog service of task 041, not a bespoke `showDialog` (FE-CONS-05).

## Definition of done

- [ ] Switching provider requires no change outside settings.
- [ ] A registry entry can declare that its key is held by the backend, and no caller behaves differently.
- [ ] A user can decline the preview and carry on working offline.
- [ ] Tests: unit tests over selection per project and per operation including a keyless entry; widget test of
      `egress_preview_dialog.dart` covering its empty and failure states.
