# 042 — Step progress list

**Phase** 03 · Design system  |  **Depends on** [030](030-color-tokens.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The done / running / waiting / failed list that processing and export both use to show where a long job has reached,
with an optional detail line per step.

## Files

- `frontend/lib/core/widgets/app_progress_steps.dart` (new)

## Contract

```dart
class ProgressStep { final String label; final StepState state; final String? detail; }
class AppProgressSteps extends StatelessWidget { final List<ProgressStep> steps; }
```

## Steps

1. Render each step with a state icon, its label and the optional detail line, in a layout that does not reflow as
   steps change state.

## Constraints

- Tokens only, no literal colour, spacing, radius or duration; nothing clips at 200 percent text scale (FE-THEME-01,
  FE-A11Y-03).
- Gallery entry covering every `StepState` and a mixed list, plus goldens in light, dark and outdoor (FE-CONS-03).
- Each step's state carries an icon and text, not colour alone (FE-A11Y-05).
- State transitions are announced to screen readers as they happen (FE-A11Y-07).

## Definition of done

- [ ] Processing and export reuse this component rather than each drawing its own progress list.
- [ ] A step changing state does not move the steps below it.
- [ ] Tests: goldens of every `StepState` and a mixed list in light, dark and outdoor; widget test that a state change
      announces itself and shifts no other step's position.
