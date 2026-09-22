# 003 — Design system: tokens, themes and the whole widget vocabulary

**Phase** 03 · Design system  |  **Depends on** [001](../01-orchestration/001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every style value and every widget a later screen composes, finished before the first feature screen exists: the four
token files — colour, type, the four-point space, radius and size scale, and tone-plus-outline elevation — each resolved
for light, dark and outdoor; three `ThemeData` values assembled from those tokens plus the persisted controller that
picks one before the first frame; the single definition of the three size classes, the responsive builder and the
readable-width constraint; `AppPage`, which is the only `Scaffold` in the application; the button vocabulary of
variant-driven button, labelled icon button and thumb-reachable primary action; the text-entry family of base input,
number field, one temporal control and the debounced search field; the selection family of shared `Choice<T>`, single
and multiple selection and the boolean tile; chip and chip row; card, list tile and section header; the status pill and
its badge form with the one mapping from `RecordStatus`; the four non-data states and the `AsyncValueView` that chooses
between them; the four interrupt APIs of dialog, sheet, snackbar and banner; the step progress list processing and
export share; the photo thumbnail every image renders through; the form scaffold with its error summary, submit bar,
unsaved-changes guard and keyboard behaviour; the haptics service; the copy catalogue every visible string comes from;
the developer gallery at `/_gallery` that a catalogue widget does not exist without an entry in; and the golden harness
with committed baselines for the whole catalogue in all three modes. Later field-feedback work is included: wider
labelled-button padding, requiredness in the field label, and a borderless overflow control.

## Files

Tokens and themes:

- `frontend/lib/app/theme/color_tokens.dart` (new)
- `frontend/lib/app/theme/typography.dart` (new)
- `frontend/lib/app/theme/dimensions.dart` (new)
- `frontend/lib/app/theme/elevation.dart` (new)
- `frontend/lib/app/theme/app_theme.dart` (new)
- `frontend/lib/app/theme/outdoor_theme.dart` (new)
- `frontend/lib/app/theme/theme_controller.dart` (new)
- `frontend/lib/app/app.dart` (changed)

Layout and the page:

- `frontend/lib/core/widgets/responsive/breakpoints.dart` (new)
- `frontend/lib/core/widgets/responsive/responsive_builder.dart` (new)
- `frontend/lib/core/widgets/responsive/content_constraint.dart` (new)
- `frontend/lib/core/widgets/app_page.dart` (new)

Inputs:

- `frontend/lib/core/widgets/app_button.dart` (new)
- `frontend/lib/core/widgets/app_icon_button.dart` (new)
- `frontend/lib/core/widgets/app_primary_action.dart` (new)
- `frontend/lib/core/widgets/fields/app_text_field.dart` (new)
- `frontend/lib/core/widgets/fields/app_number_field.dart` (new)
- `frontend/lib/core/widgets/fields/app_date_field.dart` (new)
- `frontend/lib/core/widgets/app_search_field.dart` (new)
- `frontend/lib/core/widgets/fields/choice.dart` (new)
- `frontend/lib/core/widgets/fields/app_choice_field.dart` (new)
- `frontend/lib/core/widgets/fields/app_multi_choice_field.dart` (new)
- `frontend/lib/core/widgets/fields/app_switch_tile.dart` (new)

Surfaces and status:

- `frontend/lib/core/widgets/app_chip.dart` (new)
- `frontend/lib/core/widgets/app_card.dart` (new)
- `frontend/lib/core/widgets/app_list_tile.dart` (new)
- `frontend/lib/core/widgets/app_section_header.dart` (new)
- `frontend/lib/core/widgets/app_status_pill.dart` (new)

Non-data states and interrupts:

- `frontend/lib/core/widgets/states/app_empty_state.dart` (new)
- `frontend/lib/core/widgets/states/app_error_state.dart` (new)
- `frontend/lib/core/widgets/states/app_loading_state.dart` (new)
- `frontend/lib/core/widgets/async_value_view.dart` (new)
- `frontend/lib/core/widgets/feedback/app_dialog.dart` (new)
- `frontend/lib/core/widgets/feedback/app_bottom_sheet.dart` (new)
- `frontend/lib/core/widgets/feedback/app_snackbar.dart` (new)
- `frontend/lib/core/widgets/feedback/app_banner.dart` (new)

The rest of the catalogue:

- `frontend/lib/core/widgets/app_progress_steps.dart` (new)
- `frontend/lib/core/widgets/app_photo_thumb.dart` (new)
- `frontend/lib/core/widgets/forms/app_form.dart` (new)
- `frontend/lib/core/widgets/forms/focus_actions.dart` (new)
- `frontend/lib/core/widgets/forms/keep_focused_visible.dart` (new)
- `frontend/lib/core/feedback/haptics.dart` (new)
- `frontend/lib/core/copy/copy.dart` (changed)

The gallery and goldens:

- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart` (new)
- `frontend/test/design_system/golden_harness.dart` (new)
- `frontend/test/design_system/goldens/` (new)

Follow-up files:

- `frontend/test/app/theme/app_theme_test.dart`
- `frontend/test/core/widgets/app_button_test.dart`
- `frontend/test/design_system/` goldens that draw a labelled button (`app_button_*`,
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/core/widgets/fields/app_text_field_test.dart`
- `frontend/test/core/widgets/fields/app_email_field_test.dart`
- `frontend/test/core/widgets/fields/app_phone_field_test.dart`
- `frontend/test/features/settings/presentation/operator_profile_screen_test.dart`
- `frontend/test/design_system/` goldens that draw a marked field
- `frontend/lib/core/widgets/app_overflow_menu.dart`
- `frontend/test/core/widgets/app_overflow_menu_test.dart`
- `frontend/test/design_system/app_overflow_menu/gallery_golden_test.dart`


## Contract

Tokens and themes:

```dart
abstract final class AppColors {
  final Color surface, surfaceVariant, background, outline, primary, onPrimary, secondary,
      danger, warning, success, info, confidenceHigh, confidenceMedium, confidenceLow;
}
extension AppColorsX on BuildContext { AppColors get colors; }

abstract final class AppText { static TextStyle display, title, section, body, bodyStrong, label, caption, mono; }

abstract final class Space { static const x1 = 4.0, x2 = 8.0, x3 = 12.0, x4 = 16.0, x6 = 24.0, x8 = 32.0; }
abstract final class Radii { static const sm, md, lg, pill; }
abstract final class Sizes { static const minTapTarget = 48.0, controlHeight = 52.0; }

abstract final class Elevation { static BoxDecoration surface(BuildContext c, {int level = 0}); }

ThemeData buildTheme({required Brightness brightness, bool outdoor = false});
ThemeData buildOutdoorTheme(Brightness brightness);
enum AppThemeMode { system, light, dark, outdoor }
final themeModeProvider = NotifierProvider<ThemeModeController, AppThemeMode>(...);
```

Layout and the page:

```dart
enum SizeClass { compact, medium, expanded }
extension SizeClassX on BuildContext {
  SizeClass get sizeClass;
  T responsive<T>({required T compact, T? medium, T? expanded});
}
class ResponsiveBuilder extends StatelessWidget { final WidgetBuilder compact; final WidgetBuilder? medium, expanded; }
class ContentConstraint extends StatelessWidget { final Widget child; final double maxWidth; }

class AppPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;
  final Widget? footer;
  final Future<void> Function()? onRefresh;
}
```

Inputs:

```dart
enum AppButtonVariant { primary, secondary, text, destructive }
class AppButton extends StatelessWidget {
  final String label; final VoidCallback? onPressed; final AppButtonVariant variant;
  final bool busy; final IconData? icon;
}
class AppIconButton extends StatelessWidget {
  final IconData icon; final String semanticLabel; final String tooltip; final VoidCallback? onPressed;
}
class AppPrimaryAction extends StatelessWidget {
  final String label; final String? caption; final VoidCallback? onPressed; final bool busy;
}

class AppTextField extends StatelessWidget {
  final String label; final String? hint, helper, errorText; final TextEditingController controller;
  final int? maxLines; final Widget? trailing; final bool clearable;
}
class AppNumberField extends StatelessWidget {
  final String label; final String? unit; final num? min, max; final bool decimal; final ValueChanged<num?> onChanged;
}
enum DateFieldMode { date, time, dateTime }
class AppDateField extends StatelessWidget {
  final String label; final DateFieldMode mode; final DateTime? value; final bool autoFilled;
  final ValueChanged<DateTime?> onChanged;
}
class AppSearchField extends StatelessWidget {
  final String hint; final ValueChanged<String> onChanged; final VoidCallback? onSubmitted;
  final Duration debounce; final int? resultCount;
}

class Choice<T> {
  const Choice(this.value, this.label, {this.icon});
  final T value; final String label; final IconData? icon;
}
class AppChoiceField<T> extends StatelessWidget {
  final String label; final List<Choice<T>> options; final T? value; final ValueChanged<T?> onChanged;
}
class AppMultiChoiceField<T> extends StatelessWidget {
  final String label; final List<Choice<T>> options; final Set<T> value; final ValueChanged<Set<T>> onChanged;
}
class AppSwitchTile extends StatelessWidget {
  final String title; final String? description; final bool value; final ValueChanged<bool> onChanged;
}
```

Surfaces and status:

```dart
class AppChip extends StatelessWidget {
  final String label; final IconData? icon; final bool selected; final VoidCallback? onTap, onDismiss;
}
class AppChipRow extends StatelessWidget { final List<AppChip> chips; final bool scrollable; }

class AppCard extends StatelessWidget {
  final Widget child; final EdgeInsets? padding; final VoidCallback? onTap; final int elevationLevel;
}
class AppListTile extends StatelessWidget {
  final Widget? leading, trailing; final String title; final String? subtitle;
  final AppStatusPill? status; final bool dense, selected; final VoidCallback? onTap, onLongPress;
}
class AppSectionHeader extends StatelessWidget { final String title; final Widget? action; }

class AppStatusPill extends StatelessWidget { final RecordStatus status; }
abstract final class StatusStyle { static (Color, IconData, String) of(RecordStatus s); }
```

Non-data states and interrupts:

```dart
class AppEmptyState extends StatelessWidget {
  final IconData icon; final String headline, message; final String? actionLabel; final VoidCallback? onAction;
}
class AppErrorState extends StatelessWidget { final Failure failure; final VoidCallback? onRetry; }
enum SkeletonShape { list, card, detail }
class AppSkeleton extends StatelessWidget { final SkeletonShape shape; final int count; }
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value; final Widget Function(T) data; final Widget Function()? empty;
  final bool Function(T)? isEmpty; final VoidCallback? onRetry;
}

Future<bool> showAppConfirm(BuildContext c, {required String title, required String message,
    required String confirmLabel, bool destructive = false});
Future<void> showAppAlert(BuildContext c, {required String title, required String message});
Future<T?> showAppSheet<T>(BuildContext c, {required String title, required WidgetBuilder builder});
enum SnackTone { info, success, warning, error }
void showAppSnack(BuildContext c, String message,
    {SnackTone tone = SnackTone.info, String? undoLabel, VoidCallback? onUndo});
class AppBanner extends StatelessWidget {
  final String message; final IconData icon; final SnackTone tone; final VoidCallback? onDismiss;
}
```

The rest of the catalogue:

```dart
class ProgressStep { final String label; final StepState state; final String? detail; }
class AppProgressSteps extends StatelessWidget { final List<ProgressStep> steps; }

class AppPhotoThumb extends StatelessWidget {
  final PhotoAsset photo; final double size; final bool selected; final VoidCallback? onTap, onLongPress;
}

class AppForm extends StatefulWidget {
  final List<Widget> fields; final String submitLabel;
  final Future<void> Function() onSubmit; final bool guardUnsaved;
}
extension FocusActions on BuildContext { void dismissKeyboard(); void focusNext(); }
class KeepFocusedVisible extends StatelessWidget { final Widget child; }

abstract interface class Haptics {
  void shutter(); void save(); void warning(); void error(); void selection();
}

abstract final class Copy {
  static String get notDetected;
  static String recordsCount(int n);
}
```

The gallery and goldens:

```dart
class WidgetGalleryScreen extends StatelessWidget { static const route = '/_gallery'; }

Future<void> expectGolden(WidgetTester t, Widget w, String name, {List<AppThemeMode> modes});
```

## Steps

### Tokens and themes

1. Land the four token files. Colours: surface, surfaceVariant, background, outline, primary, onPrimary, secondary,
   danger, warning, success, info and the three confidence-band colours, each given a value in all three modes and
   reached through `context.colors`. Type: display, title, section, body, bodyStrong, label, caption and mono, with
   weights and line heights chosen for reading at arm's length in sunlight. Dimensions: the four-point space scale from
   2 to 48, radii small, medium, large and pill, control heights, and `minTapTarget` at 48. Elevation: surface levels
   expressed as tone plus outline rather than shadow, mapped per mode. Swatches, the type ramp and the surface levels
   each take a gallery page with goldens, and the contrast figures are asserted rather than eyeballed.
2. Assemble the three themes and the controller that chooses one. Build `ColorScheme`, `TextTheme` and component themes
   for buttons, fields, chips, dialogs, sheets and app bars from tokens only. Derive outdoor by raising contrast,
   thickening outlines and removing low-contrast surface tints, reusing the same token names and identical geometry.
   `ThemeModeController` persists `AppThemeMode` through the `TextStore` service — memory fake in tests, file on the
   device — restores it before the first frame, and follows the system brightness when the mode is `system`.
   `TaptureApp` resolves the active `ThemeData`, so no screen selects a theme itself.

### Layout and the page

3. Define the size classes and the two helpers over them. `SizeClass` is the only place the boundaries live: compact
   below 600dp, medium 600–1023dp, expanded 1024dp and above. `context.responsive` and `ResponsiveBuilder` both fall
   back to the next smaller value or builder when one is not given. `ContentConstraint` centres its child in a 720dp
   readable column by default, overridable per screen.
4. Build `AppPage` as the one `Scaffold` in the application: themed app bar, optional subtitle line, action slot,
   scrolling body, optional footer action slot, per-size-class padding and `ContentConstraint` applied automatically,
   safe-area and keyboard insets handled here, and pull-to-refresh attached only when `onRefresh` is given. Nine
   goldens cover the three modes at the three widths.

### Inputs

5. Land the button vocabulary. `AppButton` renders all four variants from tokens, shows an inline spinner while `busy`
   and swallows taps while busy so a double submission is impossible. `AppIconButton` takes `semanticLabel` and
   `tooltip` as required constructor arguments, so an unlabelled icon button cannot compile. `AppPrimaryAction` is full
   width and glove-tall, with an optional caption line under the label and its own busy state.
6. Land the text-entry family on one base input. `AppTextField` carries label, hint, helper and error text, prefix and
   suffix slots, a clear button, single and multi-line modes, a character counter, and a trailing slot for the
   microphone or scanner; errors arrive from the shared validation display rather than being formatted here.
   `AppNumberField` shows the numeric keyboard, rejects non-numeric characters as they are typed, shows the template's
   unit as a suffix and renders an out-of-range value in the shared error style. `AppDateField` formats through the
   shared `intl` helpers, offers a picker, clears, defaults to now from the clock service, and marks a value that was
   filled in rather than typed. `AppSearchField` debounces at `AppConstants.interaction.debounce`, separates changed
   from submitted, and carries a result-count slot. Twelve goldens cover the four controls.
7. Land the selection family on the shared `Choice<T>`. `AppChoiceField` renders a segmented control under four options
   and opens a searchable sheet at four or more. `AppMultiChoiceField` opens a selection sheet with search, select-all
   and clear, and shows the current values as chips on the closed field. `AppSwitchTile` takes a title and optional
   description, is tappable across the whole tile, and ships a checkbox variant sharing the layout.

### Surfaces and status

8. Build `AppChip` as one widget covering the plain, selectable — tick plus tint — and dismissible forms; a chip with
   neither callback is not interactive and takes no tap target. `AppChipRow` wraps when `scrollable` is false and
   scrolls horizontally when it is true, in both cases without clipping a label. The multi-choice field is moved onto
   these rather than keeping chips of its own.
9. Build the three containers. `AppCard` takes its padding, radius and surface treatment from `Elevation.surface` and
   becomes tappable only when `onTap` is given. `AppListTile` supports dense and comfortable densities, a status pill
   slot, a trailing slot, selection shown as a tick for multi-select lists, tap to open and long-press to select.
   `AppSectionHeader` renders the heading from the `section` type role with an optional trailing action.
10. Build `AppStatusPill` and `StatusStyle.of`, mapping every value in the record lifecycle to a colour, an icon and a
    label; an unmapped status is a compile error, not a blank pill. Ship the compact badge form that fits the
    `AppListTile` trailing slot.

### Non-data states and interrupts

11. Land the four non-data states and the widget that chooses between them. `AppEmptyState` carries an icon, headline,
    one-line explanation and an optional primary action. `AppErrorState` maps every `Failure` subtype to a
    plain-language message and a suggested action, with retry when `onRetry` is given. `AppSkeleton` provides list,
    card and detail placeholder shapes sized to the real content, plus a small inline spinner for actions rather than a
    full-screen one. `AsyncValueView` defaults loading and error to the shared states, takes builders for data and
    empty, and treats `isEmpty` as the emptiness test on loaded data.
12. Land the four interrupt APIs. The destructive dialog variant requires an explicit action label and returns a typed
    result; cancel is always available and always returns false. The sheet has a drag handle, title, scrollable body,
    safe-area padding and the content constraint, and presents as a side panel on expanded layouts. The snackbar queues
    messages so they never overlap, across info, success, warning and error tones, with an optional undo action. The
    banner sits under the app bar for offline and warning states, is dismissible, and never takes focus. The choice and
    multi-choice fields are moved onto this sheet rather than presenting their own.

### The rest of the catalogue

13. Build `AppProgressSteps`, rendering each step with a state icon, its label and the optional detail line across
    done, running, waiting and failed, in a layout that does not reflow as steps change state.
14. Build `AppPhotoThumb`. Resolve the cached thumbnail path for the requested size and never decode a full image to
    draw a thumbnail. Show the type badge and caption indicator as overlays that do not obscure the subject, selection
    as a tick plus border, and a placeholder when the file is missing rather than an exception, all at 1:1 with
    `BoxFit.cover`. `PhotoAsset` and `PhotoType` live in a part file here until capture owns them.
15. Build the form frame and its keyboard behaviour. `AppForm` applies token field spacing, lists every invalid field
    in an error summary at the top, pins a submit bar that shows the button's busy state during `onSubmit`, and prompts
    on a dirty pop when `guardUnsaved` is set. `FocusActions` dismisses the keyboard on scroll and advances focus field
    to field in visual order. `KeepFocusedVisible` scrolls the focused field above the keyboard inset as focus moves.
16. Ship the haptics service as interface, platform implementation and recording fake: shutter is heavy, save medium,
    warning light, error a vibrate and selection a click, so capture and save are distinguishable in the hand. Read the
    system haptics setting once and suppress every pattern when it is off; reduced motion skips selection while capture
    and save still confirm by touch.
17. Fill the copy catalogue. Key by meaning, never by position — `captureSaveRaw`, not `screen3Button2`. Use
    placeholders and ICU plurals for anything with a count, never sentence concatenation. Prefer a stated absence to a
    blank: "Not detected" rather than an empty string or `null`.

### The gallery and goldens

18. Build `WidgetGalleryScreen` at `/_gallery`, grouping entries by family — tokens, layout, buttons, fields,
    containers, states, feedback — each showing every variant and state of its widgets, with switchers for theme mode,
    simulated width and text scale so a component can be compared across the matrix without a rebuild. The route is
    registered in the debug router only and stays off the production navigation surface.
19. Land the golden harness and the baselines. `expectGolden` wraps the widget in the resolved theme for each requested
    mode, pumps to a settled frame and compares one file per mode, defaulting to light, dark and outdoor. Pin the Ahem
    test font and disable animation so a baseline is reproducible on any machine. Generate and commit baselines under
    `frontend/test/design_system/goldens/` for every catalogue widget and for the gallery index.

## Constraints

- No screen invents a widget, colour, spacing value or error style this catalogue already has; tokens only, with no
  literal colour, spacing, radius or duration anywhere in a widget, a 48dp minimum target and a semantic label on every
  interactive element, and nothing clipping at 200 percent text scale (FE-THEME-01, FE-A11Y-01, FE-A11Y-02,
  FE-A11Y-03).
- Every token is defined in light, dark **and** outdoor; a token present in one mode only ships as an invisible control
  (FE-THEME-02).
- Semantic role names only — `danger`, `surface`, `outline` — never `red` or `blue700` (FE-THEME-04).
- Contrast is measured, not eyeballed: 4.5:1 body text, 3:1 large text and interactive outlines, in all three modes
  (FE-THEME-10, FE-A11Y-04).
- Outdoor changes contrast only: no padding, radius, size or position differs from light or dark (FE-THEME-03).
- Material is styled once, in the theme; a screen that decorates a stock button locally is a defect (FE-THEME-07).
- The responsive trio is the only place a `MediaQuery` width is read; features ask for a value per size class or use
  `ResponsiveBuilder` (FE-RESP-01, FE-RESP-02).
- Changing size class must not lose in-progress input or navigation state (FE-RESP-03).
- Notches, gesture bars and the keyboard are handled in `AppPage`, never by a screen (FE-RESP-08); the body always
  scrolls and no layout inside a form assumes the keyboard is closed (FE-RESP-06).
- Landscape is supported, and rotation loses nothing in the body (FE-RESP-07).
- Sizing uses aspect ratio and `BoxFit`, never fixed pixel dimensions (FE-RESP-09).
- The primary action sits within thumb reach on a large phone and is glove-friendly, and capture and save both confirm
  by touch in ways that are distinguishable without looking at the screen (FE-A11Y-09).
- Selection carries a second signal beyond colour — a tick or a shape, not only a tinted background — and a status or
  step state always carries an icon and text as well as its colour (FE-THEME-05, FE-A11Y-05).
- Appearing, dismissing and state transitions are announced to screen readers rather than left silent (FE-A11Y-07).
- Traversal order matches visual order, and switch access reaches every action including submit (FE-A11Y-06).
- The system haptics and reduced-motion settings are honoured, never overridden (FE-A11Y-08).
- Persistent storage, platform vibration and time are reached only through a `core/` service with an interface and a
  fake — never a plugin at the call site, and never `DateTime.now()` in a widget (FE-STR-11).
- Dates, times and numbers are formatted by the shared `intl` helpers against the active locale, never hand-built
  (FE-CONS-09, FE-L10N-04).
- Projects, records, templates and datasets must all be expressible with `AppListTile`, and every photo with
  `AppPhotoThumb`; a feature-local row or thumbnail is a review rejection (FE-CONS-06).
- Long-press selects and tap opens; no other gesture is bound in the catalogue (FE-CONS-10).
- Every failure renders from a typed `Failure` through `AppErrorState`; no screen writes its own error copy
  (FE-CONS-11).
- Data views render loading, empty, error and offline through `AsyncValueView`, never a hand-rolled switch
  (FE-CONS-04).
- One dialog API, one sheet API, one snackbar API; a destructive action always pairs a confirm with an undo
  (FE-CONS-05).
- Status labels and every other visible string come from the copy helper and the shared vocabulary, using the same word
  for the same concept as `lib/core/naming/domain_names.dart` — record, capture, context, template, bundle, merge,
  refine — and a synonym fails the naming checker (FE-CONS-07).
- No user-facing literal remains in a catalogue widget (FE-L10N-01, FE-L10N-02, FE-L10N-03).
- Template field labels, option lists and template names are user data: they never pass through the copy helper and are
  never translated, matched or normalised (FE-L10N-07).
- Thumbnails are cached by hash and size with a cap on concurrent decodes; decoding a full photo for a 96dp square is a
  defect (FE-PERF-04).
- Every widget here takes a gallery entry covering each variant and state, with goldens in light, dark and outdoor, and
  the responsive helpers are exercised at all three widths. The gallery is the contract: a catalogue widget missing
  from it does not exist as far as other features are concerned, and adding one without an entry fails review
  (FE-CONS-03, FE-RESP-10).
- The gallery screen composes `AppPage` and the catalogue widgets only; it defines no widget of its own (FE-CONS-01).
- Golden coverage is per widget and per mode: light, dark and outdoor for every design-system widget (FE-TEST-02).
- Pump to an explicit condition; a fixed delay in a golden test is a defect that will flake (FE-TEST-07).
- The suite runs in continuous integration and is never skipped or weakened to make a change pass (FE-TEST-06).

## Definition of done

### Tokens and themes

- [x] Changing the active mode restyles every screen with no per-widget work.
- [x] Every stock Material widget already looks like Tapture without local styling.
- [x] `Color(...)`, `TextStyle(...)`, `EdgeInsets.all(n)`, `BorderRadius.circular(n)` and `Duration(...)` literals are
      absent from feature code; every widget reaches style through the four token files (FE-THEME-01).
- [x] Cards, sheets and dialogs share one depth language that survives direct sunlight.
- [x] Switching to outdoor changes contrast and outline weight only, with geometry identical to light.
- [x] The chosen mode survives a restart and applies before the first frame, with no visible flash of the wrong theme.
- [x] Tests: unit tests under `frontend/test/design_system/tokens/` asserting the colour, dimension and elevation token
      sets are identical across light, dark and outdoor.
- [x] Tests: a contrast test asserting 4.5:1 body text and 3:1 large text and interactive outlines in all three modes.
- [x] Tests: golden of the type ramp at default and 200 percent text scale, plus swatch and surface-level goldens in
      light, dark and outdoor.
- [x] Tests: unit test that `AppThemeMode` round-trips through storage, widget test comparing light and outdoor layout
      geometry, and a golden of a sample screen in light, dark and outdoor.

### Layout and the page

- [x] No widget outside `core/widgets/responsive/` compares a `MediaQuery` width.
- [x] A two-pane layout is a one-line change in a screen.
- [x] Text and forms stay centred and capped in the readable column on expanded rather than stretching edge to edge.
- [x] Every screen in later phases composes `AppPage`; none builds its own `Scaffold`.
- [x] Pull-to-refresh appears only where refreshing means something.
- [x] Tests: unit test of size-class resolution at 599, 600, 1023 and 1024dp; widget tests of `ResponsiveBuilder` and
      `context.responsive` falling back at three widths, of a two-pane layout, and that a resize keeps in-progress
      input.
- [x] Tests: goldens of `ContentConstraint` in light, dark and outdoor.
- [x] Tests: nine `AppPage` goldens — light, dark and outdoor at compact, medium and expanded — plus widget tests that
      the body scrolls without overflow at 200 percent text scale in both orientations and that rotation loses nothing.

### Inputs

- [x] No feature constructs an `ElevatedButton`, `TextButton`, `OutlinedButton` or `IconButton` directly.
- [x] A busy button ignores taps; an icon button without a semantic label fails to compile.
- [x] Capture and review use the identical primary action control.
- [x] Later fields and screens compose these instead of `TextFormField`; typing a letter into a number field is
      impossible and out-of-range values show the shared error style.
- [x] Auto-filled dates are visibly distinct from typed ones in all three modes.
- [x] Search fires once per debounce window, not once per keystroke; records, datasets and template pickers all use it.
- [x] A 200-option list stays usable on a compact screen, and selected values are readable without opening the sheet.
- [x] Settings screens and boolean template fields share one control.
- [x] Tests: goldens per button variant and state in light, dark and outdoor; widget test that a busy button swallows
      taps; widget test asserting all three button controls satisfy the 48dp accessibility matcher.
- [x] Tests: widget tests for error display, clearing, non-numeric rejection and range violation.
- [x] Tests: widget test of the date field against a frozen clock covering all three `DateFieldMode` values, and widget
      test of the debounce window under fake async.
- [x] Tests: twelve goldens covering the four text-entry controls empty, filled, error, disabled and multi-line in
      light, dark and outdoor.
- [x] Tests: widget tests of the presentation switch either side of the four-option boundary, of search over a
      200-option list, of select-all and clear, and that tapping anywhere on a switch tile toggles it.
- [x] Tests: nine goldens of the three selection controls across the segmented and sheet presentations and empty,
      partial and full selection, in light, dark and outdoor.

### Surfaces and status

- [x] The context bar and filter bar are assembled from `AppChip` and define no chip of their own.
- [x] A long chip label at 200 percent text scale truncates or wraps rather than clipping.
- [x] Lists and detail sections share one container, and projects, records, templates and datasets share one row.
- [x] Selection and status are readable without relying on colour.
- [x] A colour-blind user in direct sunlight can still read the status, and every status in the app renders through
      `AppStatusPill`; no screen maps status to colour itself.
- [x] Tests: widget tests that tap selects and dismiss removes, and that a row wraps or scrolls without clipping a
      label; three chip goldens covering plain, selected, dismissible and an overflowing row in light, dark and
      outdoor.
- [x] Tests: widget test that long-press selects and tap opens; nine goldens of the card, of the row dense,
      comfortable, selected, with status and with trailing, and of the section header, in light, dark and outdoor.
- [x] Tests: unit test that `StatusStyle.of` is exhaustive over `RecordStatus`; widget tests that icon and label
      accompany the colour; three goldens of every status in light, dark and outdoor.

### Non-data states and interrupts

- [x] Every list screen shows a helpful empty state rather than blank space, and no screen shows a raw exception
      string.
- [x] Screens do not jump when data arrives, because the skeleton occupies the same space as the content.
- [x] Feature screens contain no manual async state switching.
- [x] Delete flows across the app look and behave identically, and every destructive action can offer undo through one
      call.
- [x] Pickers and option sheets share one presentation and become a side panel on expanded layouts.
- [x] Offline state is visible through the banner without stealing focus from the field being edited.
- [x] Tests: widget test per `Failure` subtype asserting its message and that retry fires; widget test of
      `AsyncValueView` across loading, error, empty and data; three goldens of the four states in light, dark and
      outdoor.
- [x] Tests: widget tests of the confirm and cancel paths, of undo invoking its callback, of two snacks queueing rather
      than overlapping, and of the sheet at compact and expanded widths; three goldens of dialog, sheet, snack and
      banner in light, dark and outdoor.

### The rest of the catalogue

- [x] Processing and export reuse `AppProgressSteps` rather than each drawing its own progress list.
- [x] A step changing state does not move the steps below it.
- [x] Every photo in the app renders through `AppPhotoThumb` (FE-CONS-06).
- [x] Scrolling a tray of thirty photos stays smooth, and a missing file shows a placeholder instead of throwing.
- [x] Leaving a dirty form always prompts, on every screen that uses `AppForm`.
- [x] A long form stays usable on a compact phone with the keyboard open; the focused field is never hidden behind it.
- [x] Submitting twice runs `onSubmit` once.
- [x] Shutter and save feel distinct in the hand, and every pattern is silent when the system setting is off.
- [x] No inline user-facing string remains in any `core/widgets/` file, and a count reads correctly at zero, one and
      many.
- [x] Tests: widget test that a state change announces itself and shifts no other step's position; three goldens of
      every `StepState` and of a mixed list in light, dark and outdoor.
- [x] Tests: widget test asserting the full-size image is never decoded and one covering the missing-file path; three
      goldens of badge, caption, selected, unselected and error in light, dark and outdoor.
- [x] Tests: widget tests of the unsaved-changes guard, of a double submission running `onSubmit` once, and that focus
      advances in visual order with the focused field staying visible under a simulated keyboard inset; three goldens
      of the form with and without the error summary in light, dark and outdoor.
- [x] Tests: unit tests against the recording fake asserting each named pattern fires once, that all five are
      suppressed when haptics are disabled, and that reduced motion skips selection.
- [x] Tests: unit tests of the plural forms at 0, 1 and 2, and a test asserting no `Copy` value uses a synonym the
      naming checker rejects.

### The gallery and goldens

- [x] Every widget built in this phase appears in the gallery in every state it can render.
- [x] A developer can compare light, dark and outdoor side by side at three widths without restarting the app, and the
      route stays off the production navigation surface while remaining reachable in debug builds.
- [x] An unintended styling change fails the suite and names the widget and mode that moved.
- [x] Regenerating baselines on a clean tree produces no diff.
- [x] Tests: widget test enumerating `core/widgets/` and failing when a public catalogue widget has no gallery entry;
      goldens of the gallery index in light, dark and outdoor.
- [x] Tests: the golden suite covers every widget built in this phase in all three modes and runs in continuous
      integration, with a fixture proving a deliberate one-pixel change is caught.

### Follow-up work

#### Widen button horizontal padding

- [x] Filled, outlined and text buttons have `Space.x4` between the label and each side.
- [x] "Create a project" on the empty Projects list no longer touches its outline, in light, dark
      and outdoor.
- [x] Buttons in dialogs, forms, empty states and footers still fit at 360 dp and 200 percent text.
- [x] Icon buttons and the floating button are pixel-identical to before.
- [x] Light and outdoor share geometry.
- [x] Tests: theme asserts `Space.x4` padding on filled, outlined and text buttons in all three
      themes; outdoor geometry still matches light; a long `AppButton` label at 360 dp and 200
      percent text wraps without overflow.

#### Move requiredness into field labels

- [x] New project shows "Name (required)", "Description (optional)" and "Organisation
      (optional)", with no caption under the boxes.
- [x] Operator, project details and project settings show the same pattern.
- [x] A screen reader announces the mark with the label.
- [x] Fields fit at 360 dp, in landscape and at 200 percent text, in light, dark and outdoor.
- [x] Tests: a required field's label reads "Name (required)" empty and focused, with no
      "Required" caption; an optional field with a helper shows "(optional)" in the label and
      the helper below; an unmarked field is unchanged; semantics include the mark; no
      overflow at 360 dp and 200 percent text.

#### Add a borderless overflow control

- [x] `AppOverflowMenu()` with no extra arguments renders as it does today.
- [x] `AppOverflowMenu(outlined: false)` has no border, stays 48 dp, and opens the same menu.
- [x] Hover, focus and press use `surfaceVariant` in light, dark and outdoor.
- [x] At rest the borderless glyph is full `onSurface` ink and meets contrast in all three themes.
- [x] Both variants appear in the widget gallery in every state.
- [x] Tests: default still paints a border; borderless paints none; both keep the target, label
      and tooltip; both open and select; focus-traversal shows a visible indicator on the
      borderless variant; goldens for both variants in light, dark and outdoor at default and
      200 percent text.




## Follow-up absorbed from 318, 319, 326

### Widen button horizontal padding

Every labelled button keeps a comfortable gap between its label and its outline. Filled, outlined and
text buttons share one horizontal padding token. Icon buttons, the floating button and the primary
action's full-width layout stay as they are.

Files:

- `frontend/lib/app/theme/app_theme.dart`
- `frontend/test/app/theme/app_theme_test.dart`
- `frontend/test/core/widgets/app_button_test.dart`
- `frontend/test/design_system/` goldens that draw a labelled button (`app_button_*`,
  `app_dialog_*`, `app_empty_state_*`, `app_error_state_*`, `app_section_header_*`,
  `theme_preview_*`, `widget_gallery_index_*`, `gallery_index_*`). `app_form_*` was
  regenerated and stayed identical because submit uses `AppPrimaryAction`.

Constraints:

- Style Material once, in `app_theme.dart`; no per-screen padding (FE-THEME-07).
- A token value, never a literal (FE-THEME-01, FE-THEME-11).
- Outdoor keeps identical geometry (FE-THEME-03).
- 48 dp targets, and labels wrap rather than clip at 200 percent (FE-A11Y-01, FE-A11Y-03).
- Labels 35 percent longer still fit (FE-L10N-06).
- Catalogue goldens in all three themes (FE-CONS-03, FE-TEST-02).
- Do not change `AppIconButton`, the floating Feedback button, `AppPrimaryAction`'s full-width
  layout, button height, radius or text style.

### Move requiredness into field labels

A marked text field says whether it is required or optional in its label, for example
"Name (required)" and "Description (optional)", both while empty and once floated. There is
no separate caption. Unmarked fields stay as they are.

Files:

- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/core/widgets/fields/app_text_field.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/core/widgets/fields/app_text_field_test.dart`
- `frontend/test/core/widgets/fields/app_email_field_test.dart`
- `frontend/test/core/widgets/fields/app_phone_field_test.dart`
- `frontend/test/features/settings/presentation/operator_profile_screen_test.dart`
- `frontend/test/design_system/` goldens that draw a marked field

Constraints:

- One change in `AppTextField`; screens keep passing `requiredness` (FE-CONS-01).
- Never concatenate. Use a placeholder message so the word order can change per language
  (FE-L10N-03).
- `Copy` keys that name meaning, and labels that survive a 35 percent expansion (FE-L10N-01,
  FE-L10N-02, FE-L10N-06).
- The semantic label includes the mark, so requiredness is not colour-only (FE-A11Y-02,
  FE-A11Y-05).
- Long labels wrap or ellipsise without clipping the field at 200 percent (FE-A11Y-03,
  FE-RESP-06).
- Do not change the `FieldRequiredness` enum or its default, validation, error text, counters,
  dictation, or fields other than `AppTextField` and its wrappers.

### Add a borderless overflow control

`AppOverflowMenu` gains an `outlined` flag that matches `AppIconButton`. The default stays
outlined so every current call site is unchanged. `outlined: false` drops the box, keeps the
48 dp target, and paints a token surface on hover, focus and press. The rest-state glyph stays
full `onSurface` ink on every platform.

Files:

- `frontend/lib/core/widgets/app_overflow_menu.dart`
- `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`
- `frontend/test/core/widgets/app_overflow_menu_test.dart`
- `frontend/test/design_system/app_overflow_menu/gallery_golden_test.dart`

Constraints:

- Extend the catalogue widget; do not fork a second three-dot control (FE-CONS-01, FE-CONS-02).
- The gallery ships both variants in rest, hover, focus, pressed and disabled (FE-CONS-03).
- Tokens only for hover, focus and press — `surfaceVariant`, never a literal fill (FE-THEME-01,
  FE-THEME-11). Separate by tone, not shadow (FE-THEME-06).
- Outdoor changes contrast, not geometry (FE-THEME-03, FE-THEME-10).
- 48 dp, a required label and tooltip, and a focus indicator that is visible without the border
  (FE-A11Y-01, FE-A11Y-02, FE-A11Y-06).
- Do not change the default, the menu sheet, `showAppOverflowActions`, `AppIconButton`, the
  central `iconButtonTheme`, or any call site. Adopting the flag on the project row is 006.

## Out of scope

- Validation rules themselves: the fields render the errors handed to them, they do not decide them.
- The settings screen control that changes the theme mode, which belongs to 007 · Account and settings.
- Adaptive navigation — bottom bar, rail, rail plus pane — which belongs to 006 · Application shell.
- Sound feedback; no audible confirmation is part of this phase.
- Screen-level goldens for feature phases; each feature phase commits its own.
