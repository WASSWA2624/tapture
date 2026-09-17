# 017 — Accessibility test matchers

**Phase** 01 · Project setup and guardrails  |  **Depends on** [004](004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`frontend/test/support/a11y_matchers.dart` gives every later widget test one way to assert semantics, tap-target size
and text-scale survival, so accessibility is asserted rather than eyeballed.

## Files

- `frontend/test/support/a11y_matchers.dart` (new)

## Contract

```dart
Matcher hasSemanticLabel(String label);  Matcher meetsTapTarget({double min = 48});  Future<void> expectNoA11yIssues(WidgetTester t)
```

## Steps

1. Implement matchers for semantic label presence, minimum tap target size and survival of 200 percent text scale without clipping.
2. Implement `expectNoA11yIssues`, which runs the framework accessibility guidelines over the pumped widget.

## Constraints

- 48dp is the minimum for every interactive element, including icon buttons, chips and list actions (FE-A11Y-01).
- Failure messages name the offending widget and the measured value, since these matchers are the only accessibility evidence a design-system test produces (FE-A11Y-10).
- The 200 percent case asserts no clipping in either orientation (FE-A11Y-03, FE-RESP-06).

## Definition of done

- [x] A button without a semantic label fails `hasSemanticLabel` with a readable message.
- [x] A 40dp icon button fails `meetsTapTarget`, and a 48dp one passes.
- [x] `expectNoA11yIssues` fails a widget that breaks the framework guidelines and passes a compliant one.
- [x] Tests: `frontend/test/support/a11y_matchers_test.dart` proves each matcher both passes and fails correctly.
