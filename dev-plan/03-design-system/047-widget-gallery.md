# 047 — Widget gallery screen

**Phase** 03 · Design system  |  **Depends on** [038](038-app-card.md), [039](039-app-status-pill.md), [040](040-app-empty-state.md), [041](041-app-dialog-service.md), [043](043-app-photo-thumb.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A developer-only screen at `/_gallery` listing every catalogue widget in every state, with switchers for theme mode,
width and text scale, so the whole vocabulary can be seen and compared before a feature screen is written.

## Files

- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart` (new)

## Contract

```dart
class WidgetGalleryScreen extends StatelessWidget { static const route = '/_gallery'; }
```

## Steps

1. Group entries by family — tokens, layout, buttons, fields, containers, states, feedback — each showing every variant
   and state of its widgets.
2. Add switchers for theme mode, simulated width and text scale so a component can be compared across the matrix
   without a rebuild.
3. Keep the route out of the production navigation surface while remaining reachable in debug builds.

## Constraints

- The gallery is the contract: a catalogue widget missing from here does not exist as far as other features are
  concerned, and adding one without an entry fails review (FE-CONS-03).
- The screen composes `AppPage` and the catalogue widgets only; it defines no widget of its own (FE-CONS-01).
- Nothing clips at 200 percent text scale in any entry, at any of the three widths (FE-A11Y-03, FE-RESP-10).

## Definition of done

- [ ] Every widget built in this phase appears here in every state it can render.
- [ ] A developer can compare light, dark and outdoor side by side at three widths without restarting the app.
- [ ] Tests: widget test enumerating `core/widgets/` and failing when a public catalogue widget has no gallery entry;
      goldens of the gallery index in light, dark and outdoor.
