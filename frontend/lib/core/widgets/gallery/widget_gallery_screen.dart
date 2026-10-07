import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:image/image.dart' as img;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/color_swatches.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/app/theme/surface_levels.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/app/theme/type_ramp.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_brand_lockup.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_floating_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_ink_picker.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_list_viewport.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/app_recording_bar.dart';
import 'package:tapture/core/widgets/app_recording_phase.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/app_toolbar_scope.dart';
import 'package:tapture/core/widgets/app_transcript_view.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/error_boundary.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_panel_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_checkbox_group.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/app_email_field.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_number_field.dart';
import 'package:tapture/core/widgets/fields/app_phone_field.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/forms/keep_focused_visible.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

/// Developer-only catalogue of every design-system widget, at `/_gallery`.
///
/// Switchers compare theme, width and text scale without a restart
/// (FE-CONS-03). The screen composes [AppPage] and catalogue widgets only.
class WidgetGalleryScreen extends StatefulWidget {
  /// Creates the gallery. Extra [initialTheme] lets goldens pin a mode.
  const WidgetGalleryScreen({
    super.key,
    this.initialTheme = AppThemeMode.light,
    this.initialSize = SizeClass.compact,
    this.initialTextScale = 1,
  });

  /// Debug-only path. Production navigation never lists this.
  static const String route = '/_gallery';

  /// Theme shown on the first frame.
  final AppThemeMode initialTheme;

  /// Simulated width class on the first frame.
  final SizeClass initialSize;

  /// Text scale on the first frame.
  final double initialTextScale;

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  MarkupInk _ink = MarkupInk.red;
  int _inkSize = 1;
  static final FixedClock _clock = FixedClock(DateTime.utc(2026, 9, 17, 12));

  /// A small encoded photo for the thumb drawn from bytes, as a browser's
  /// capture tray draws it.
  static final Uint8List _photoBytes = _gradientPhoto();
  List<Choice<AppThemeMode>> get _themes => <Choice<AppThemeMode>>[
    Choice<AppThemeMode>(AppThemeMode.light, Copy.of(context).galleryLight),
    Choice<AppThemeMode>(AppThemeMode.dark, Copy.of(context).galleryDark),
    Choice<AppThemeMode>(AppThemeMode.outdoor, Copy.of(context).galleryOutdoor),
  ];
  List<Choice<SizeClass>> get _widths => <Choice<SizeClass>>[
    Choice<SizeClass>(SizeClass.compact, Copy.of(context).galleryCompact),
    Choice<SizeClass>(SizeClass.medium, Copy.of(context).galleryMedium),
    Choice<SizeClass>(SizeClass.expanded, Copy.of(context).galleryExpanded),
  ];
  List<Choice<double>> get _scales => <Choice<double>>[
    Choice<double>(1, Copy.of(context).galleryScale100),
    Choice<double>(2, Copy.of(context).galleryScale200),
  ];
  static const List<Choice<String>> _grades = <Choice<String>>[
    Choice<String>('a', 'A'),
    Choice<String>('b', 'B'),
    Choice<String>('c', 'C'),
  ];
  static const List<Choice<String>> _tags = <Choice<String>>[
    Choice<String>('water', 'Water'),
    Choice<String>('steam', 'Steam'),
    Choice<String>('gas', 'Gas'),
    Choice<String>('oil', 'Oil'),
    Choice<String>('coal', 'Coal'),
    Choice<String>('solar', 'Solar'),
  ];

  late AppThemeMode _theme;
  late SizeClass _size;
  late double _textScale;
  late final TextEditingController _empty;
  late final TextEditingController _filled;
  late final TextEditingController _error;
  late final TextEditingController _multiline;
  late final TextEditingController _formName;

  @override
  void initState() {
    super.initState();
    _theme = widget.initialTheme == AppThemeMode.system
        ? AppThemeMode.light
        : widget.initialTheme;
    _size = widget.initialSize;
    _textScale = widget.initialTextScale;
    _empty = TextEditingController();
    _filled = TextEditingController(text: 'Ada');
    _error = TextEditingController();
    _multiline = TextEditingController(text: 'A long caption that wraps.');
    _formName = TextEditingController();
  }

  @override
  void dispose() {
    _empty.dispose();
    _filled.dispose();
    _error.dispose();
    _multiline.dispose();
    _formName.dispose();
    super.dispose();
  }

  double _previewWidth(double windowWidth) {
    final double wanted = switch (_size) {
      SizeClass.compact => 390,
      SizeClass.medium => 800,
      SizeClass.expanded => 1024,
    };
    return math.min(wanted, windowWidth);
  }

  ThemeData _themeData(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.dark => buildTheme(brightness: Brightness.dark),
      AppThemeMode.outdoor => buildOutdoorTheme(Brightness.light),
      AppThemeMode.light ||
      AppThemeMode.system => buildTheme(brightness: Brightness.light),
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LocalizedCopy localCopy = Copy.of(context);

        final double width = _previewWidth(constraints.maxWidth);
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : constraints.maxWidth;
        final ThemeData theme = _themeData(_theme);
        return Theme(
          data: theme,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(_textScale),
              size: Size(width, height),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                child: AppPage(
                  title: localCopy.galleryTitle,
                  leading: AppBrandLockup(
                    showName: false,
                    inverted: _theme != AppThemeMode.dark,
                  ),
                  actions: <Widget>[
                    AppIconButton(
                      icon: AppIcons.theme,
                      semanticLabel: localCopy.galleryTheme,
                      tooltip: localCopy.galleryTheme,
                      onPressed: _noop,
                    ),
                  ],
                  overflow: <AppOverflowAction>[
                    AppOverflowAction(
                      icon: AppIcons.save,
                      label: localCopy.save,
                      onTap: _noop,
                    ),
                  ],
                  footer: AppPrimaryAction(
                    label: localCopy.save,
                    caption: localCopy.recordsCount(2),
                    onPressed: _noop,
                  ),
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ..._switchers(),
                      ..._compare(),
                      ..._tokens(),
                      ..._layout(),
                      ..._buttons(),
                      ..._fields(),
                      ..._containers(),
                      ..._states(),
                      ..._feedback(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _switchers() {
    final LocalizedCopy localCopy = Copy.of(context);

    return <Widget>[
      AppChoiceField<AppThemeMode>(
        label: localCopy.galleryTheme,
        options: _themes,
        value: _theme,
        onChanged: (AppThemeMode? value) {
          if (value != null) {
            setState(() => _theme = value);
          }
        },
      ),
      const SizedBox(height: Space.x4),
      AppChoiceField<SizeClass>(
        label: localCopy.galleryWidth,
        options: _widths,
        value: _size,
        onChanged: (SizeClass? value) {
          if (value != null) {
            setState(() => _size = value);
          }
        },
      ),
      const SizedBox(height: Space.x4),
      AppChoiceField<double>(
        label: localCopy.galleryTextScale,
        options: _scales,
        value: _textScale,
        onChanged: (double? value) {
          if (value != null) {
            setState(() => _textScale = value);
          }
        },
      ),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _compare() {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<Widget> previews = <Widget>[
      for (final Choice<AppThemeMode> choice in _themes)
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: Space.x2),
            child: Theme(
              data: _themeData(choice.value),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(choice.label, style: AppText.caption),
                    const SizedBox(height: Space.x2),
                    AppButton(label: localCopy.save, onPressed: _noop),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
    return <Widget>[
      ResponsiveBuilder(
        compact: (BuildContext context) {
          final LocalizedCopy localCopy = Copy.of(context);

          return Column(
            children: <Widget>[
              for (final Choice<AppThemeMode> choice in _themes) ...<Widget>[
                Theme(
                  data: _themeData(choice.value),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(choice.label, style: AppText.caption),
                        const SizedBox(height: Space.x2),
                        AppButton(label: localCopy.save, onPressed: _noop),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Space.x2),
              ],
            ],
          );
        },
        medium: (BuildContext context) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: previews,
          );
        },
      ),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _tokens() {
    final LocalizedCopy localCopy = Copy.of(context);

    return <Widget>[
      AppSectionHeader(title: localCopy.galleryTokens),
      const SizedBox(height: Space.x12 * 6, child: ColorSwatches()),
      const SizedBox(height: Space.x4),
      const SizedBox(height: Space.x12 * 8, child: TypeRamp()),
      const SizedBox(height: Space.x4),
      const SizedBox(height: Space.x12 * 6, child: SurfaceLevels()),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _layout() {
    final LocalizedCopy localCopy = Copy.of(context);

    return <Widget>[
      AppSectionHeader(title: localCopy.galleryLayout),
      const AppBrandLockup(),
      const SizedBox(height: Space.x3),
      ContentConstraint(
        child: AppCard(
          child: Text(localCopy.galleryLayout, style: AppText.body),
        ),
      ),
      const SizedBox(height: Space.x4),
      ResponsiveBuilder(
        compact: (BuildContext context) {
          final LocalizedCopy localCopy = Copy.of(context);

          return AppCard(
            child: Text(localCopy.galleryCompact, style: AppText.body),
          );
        },
        medium: (BuildContext context) {
          final LocalizedCopy localCopy = Copy.of(context);

          return AppCard(
            child: Text(localCopy.galleryMedium, style: AppText.body),
          );
        },
        expanded: (BuildContext context) {
          final LocalizedCopy localCopy = Copy.of(context);

          return AppCard(
            child: Text(localCopy.galleryExpanded, style: AppText.body),
          );
        },
      ),
      const SizedBox(height: Space.x4),
      // Stacked on compact; one row, one part to two, from medium up.
      ResponsivePair(
        start: AppButton(
          label: localCopy.cancel,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: _noop,
        ),
        end: AppButton(label: localCopy.save, expand: true, onPressed: _noop),
        endFlex: 2,
      ),
      const SizedBox(height: Space.x4),
      // One level row at every width, even shares.
      ResponsivePair(
        stacksOnCompact: false,
        matchesHeights: true,
        gap: Space.x2,
        start: AppButton(
          label: localCopy.cancel,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: _noop,
        ),
        end: AppButton(label: localCopy.save, expand: true, onPressed: _noop),
      ),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _buttons() {
    final LocalizedCopy localCopy = Copy.of(context);

    return <Widget>[
      AppSectionHeader(title: localCopy.galleryButtons),
      for (final AppButtonVariant variant
          in AppButtonVariant.values) ...<Widget>[
        Wrap(
          spacing: Space.x2,
          runSpacing: Space.x2,
          children: <Widget>[
            AppButton(
              label: localCopy.save,
              variant: variant,
              onPressed: _noop,
            ),
            AppButton(
              label: localCopy.save,
              variant: variant,
              busy: true,
              onPressed: _noop,
            ),
            AppButton(label: localCopy.save, variant: variant),
            AppButton(
              label: localCopy.save,
              variant: variant,
              icon: AppIcons.check,
              onPressed: _noop,
            ),
          ],
        ),
        const SizedBox(height: Space.x3),
      ],
      AppButton(
        label: localCopy.save,
        variant: AppButtonVariant.secondary,
        expand: true,
        onPressed: _noop,
      ),
      const SizedBox(height: Space.x2),
      AppPrimaryAction(label: localCopy.save, onPressed: _noop),
      const SizedBox(height: Space.x3),
      // Toolbar ink resolved for both plain icons and Material controls.
      AppToolbarScope(
        ink: context.colors.primary,
        child: Row(
          children: <Widget>[
            AppIconButton(
              icon: AppIcons.search,
              semanticLabel: localCopy.galleryFields,
              tooltip: localCopy.galleryFields,
              onPressed: _noop,
            ),
            const SizedBox(width: Space.x2),
            AppIconButton(
              icon: AppIcons.dictating,
              semanticLabel: localCopy.galleryFields,
              tooltip: localCopy.galleryFields,
              selected: true,
              outlined: false,
              onPressed: _noop,
            ),
          ],
        ),
      ),
      const SizedBox(height: Space.x3),
      ..._overflowMenus(),
      const SizedBox(height: Space.x3),
      SizedBox(
        height: Sizes.minTapTarget * 3,
        child: Stack(
          children: <Widget>[
            AppFloatingButton(
              icon: AppIcons.feedback,
              label: localCopy.feedback,
              hint: localCopy.feedbackButtonHint,
              onPressed: _ignoreAnchor,
            ),
          ],
        ),
      ),
      const SizedBox(height: Space.x3),
      AppPrimaryAction(label: localCopy.save),
      const SizedBox(height: Space.x3),
      AppPrimaryAction(label: localCopy.save, busy: true, onPressed: _noop),
      const SizedBox(height: Space.x3),
      ShellHeaderScope(
        ownsHeader: true,
        child: Text(localCopy.settingsStorageTitle, style: AppText.bodyStrong),
      ),
      const SizedBox(height: Space.x3),
      // The recording controls in every phase.
      for (final AppRecordingPhase phase
          in AppRecordingPhase.values) ...<Widget>[
        AppRecordingBar(
          phase: phase,
          elapsed: const Duration(minutes: 1, seconds: 5),
          level: 0.4,
          onStart: _noop,
          onPause: _noop,
          onResume: _noop,
          onStop: _noop,
          onCancel: _noop,
        ),
        const SizedBox(height: Space.x3),
      ],
      const SizedBox(height: Space.x3),
    ];
  }

  List<Widget> _overflowMenus() {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<AppOverflowAction> items = <AppOverflowAction>[
      AppOverflowAction(
        icon: AppIcons.save,
        label: localCopy.save,
        onTap: _noop,
      ),
    ];
    final Color fill = context.colors.surfaceVariant;
    final List<AppOverflowAction> grouped = <AppOverflowAction>[
      AppOverflowAction(
        sectionLabel: localCopy.projectMenuCaptureReview,
        icon: AppIcons.transcript,
        label: localCopy.transcribeTitle,
        onTap: _noop,
      ),
      AppOverflowAction(
        sectionLabel: localCopy.projectMenuCaptureReview,
        icon: AppIcons.recordAudio,
        label: localCopy.meetingStartEntry,
        onTap: _noop,
      ),
      AppOverflowAction(
        sectionLabel: localCopy.projectMenuSetup,
        icon: AppIcons.context,
        label: localCopy.contextHierarchyTitle,
        onTap: _noop,
      ),
    ];
    return <Widget>[
      Wrap(
        spacing: Space.x2,
        runSpacing: Space.x2,
        children: <Widget>[
          AppOverflowMenu(
            key: const ValueKey<String>('app-overflow'),
            outlined: true,
            items: items,
          ),
          _overflowFill(
            key: const ValueKey<String>('app-overflow-hover'),
            fill: fill,
            child: AppOverflowMenu(outlined: true, items: items),
          ),
          _overflowFill(
            key: const ValueKey<String>('app-overflow-focus'),
            fill: fill,
            child: AppOverflowMenu(outlined: true, items: items),
          ),
          _overflowFill(
            key: const ValueKey<String>('app-overflow-pressed'),
            fill: fill,
            child: AppOverflowMenu(outlined: true, items: items),
          ),
          const AppOverflowMenu(
            key: ValueKey<String>('app-overflow-disabled'),
            outlined: true,
            items: <AppOverflowAction>[],
          ),
          AppOverflowMenu(
            key: const ValueKey<String>('app-overflow-borderless'),
            outlined: false,
            items: items,
          ),
          _overflowFill(
            key: const ValueKey<String>('app-overflow-borderless-hover'),
            fill: fill,
            child: AppOverflowMenu(outlined: false, items: items),
          ),
          _overflowFill(
            key: const ValueKey<String>('app-overflow-borderless-focus'),
            fill: fill,
            child: AppOverflowMenu(outlined: false, items: items),
          ),
          _overflowFill(
            key: const ValueKey<String>('app-overflow-borderless-pressed'),
            fill: fill,
            child: AppOverflowMenu(outlined: false, items: items),
          ),
          const AppOverflowMenu(
            key: ValueKey<String>('app-overflow-borderless-disabled'),
            outlined: false,
            items: <AppOverflowAction>[],
          ),
          AppOverflowMenu(
            key: const ValueKey<String>('app-overflow-grouped'),
            items: grouped,
          ),
          _overflowFill(
            key: const ValueKey<String>('app-overflow-grouped-keyboard'),
            fill: fill,
            child: AppOverflowMenu(items: grouped),
          ),
          MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: AppOverflowMenu(
              key: const ValueKey<String>('app-overflow-grouped-text2'),
              items: grouped,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _overflowFill({
    required Key key,
    required Color fill,
    required Widget child,
  }) {
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: child,
    );
  }

  List<Widget> _fields() {
    final LocalizedCopy localCopy = Copy.of(context);

    return <Widget>[
      AppSectionHeader(title: localCopy.galleryFields),
      KeepFocusedVisible(
        child: AppTextField(
          label: Copy.of(context).gallerySampleName,
          controller: _empty,
          hint: Copy.of(context).gallerySampleName,
        ),
      ),
      const SizedBox(height: Space.x4),
      AppTextField(
        label: Copy.of(context).gallerySampleName,
        controller: _filled,
        clearable: true,
      ),
      const SizedBox(height: Space.x4),
      AppTextField(
        label: Copy.of(context).gallerySampleName,
        controller: _empty,
        requiredness: FieldRequiredness.required,
      ),
      const SizedBox(height: Space.x4),
      AppTextField(
        label: Copy.of(context).gallerySampleName,
        controller: _filled,
        helper: localCopy.autoFilled,
        requiredness: FieldRequiredness.optional,
      ),
      const SizedBox(height: Space.x4),
      AppTextField(
        label: Copy.of(context).gallerySampleName,
        controller: _error,
        errorText: localCopy.outOfRange,
      ),
      const SizedBox(height: Space.x4),
      AppTextField(
        label: Copy.of(context).gallerySampleName,
        controller: _empty,
        enabled: false,
      ),
      const SizedBox(height: Space.x4),
      AppTextField(
        label: Copy.of(context).gallerySampleCaption,
        controller: _multiline,
        maxLines: 4,
        maxLength: 80,
      ),
      const SizedBox(height: Space.x4),
      AppNumberField(
        label: Copy.of(context).gallerySampleCount,
        min: 0,
        max: 10,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppNumberField(
        label: Copy.of(context).gallerySampleCount,
        enabled: false,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppEmailField(
        label: Copy.of(context).gallerySampleEmail,
        controller: _empty,
      ),
      const SizedBox(height: Space.x4),
      AppEmailField(
        label: Copy.of(context).gallerySampleEmail,
        controller: _filled,
      ),
      const SizedBox(height: Space.x4),
      AppEmailField(
        label: Copy.of(context).gallerySampleEmail,
        controller: _error,
        errorText: localCopy.outOfRange,
      ),
      const SizedBox(height: Space.x4),
      AppEmailField(
        label: Copy.of(context).gallerySampleEmail,
        controller: _empty,
        enabled: false,
      ),
      const SizedBox(height: Space.x4),
      AppPhoneField(
        label: Copy.of(context).gallerySamplePhone,
        controller: _empty,
      ),
      const SizedBox(height: Space.x4),
      AppPhoneField(
        label: Copy.of(context).gallerySamplePhone,
        controller: _filled,
      ),
      const SizedBox(height: Space.x4),
      AppPhoneField(
        label: Copy.of(context).gallerySamplePhone,
        controller: _error,
        errorText: localCopy.outOfRange,
      ),
      const SizedBox(height: Space.x4),
      AppPhoneField(
        label: Copy.of(context).gallerySamplePhone,
        controller: _empty,
        enabled: false,
      ),
      const SizedBox(height: Space.x4),
      AppDateField(
        label: Copy.of(context).gallerySampleWhen,
        mode: DateFieldMode.date,
        clock: _clock,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppDateField(
        label: Copy.of(context).gallerySampleWhen,
        mode: DateFieldMode.time,
        value: _clock.nowUtc(),
        clock: _clock,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppDateField(
        label: Copy.of(context).gallerySampleWhen,
        mode: DateFieldMode.dateTime,
        value: _clock.nowUtc(),
        autoFilled: true,
        clock: _clock,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppSearchField(hint: localCopy.search, resultCount: 2, onChanged: (_) {}),
      const SizedBox(height: Space.x4),
      AppSearchField(
        hint: localCopy.search,
        onChanged: (_) {},
        onFilter: _noop,
        activeFilterCount: 1,
      ),
      const SizedBox(height: Space.x4),
      AppChoiceField<String>(
        label: Copy.of(context).gallerySampleGrade,
        options: _grades,
        value: 'a',
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppChoiceField<String>(
        label: Copy.of(context).gallerySampleGrade,
        options: _grades,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppChoiceField<String>(
        label: Copy.of(context).gallerySampleFuel,
        options: _tags,
        value: 'water',
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppChoiceField<String>(
        label: Copy.of(context).gallerySampleGrade,
        options: _grades.take(1).toList(),
        value: 'a',
        alwaysSheet: true,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppRadioGroup<String>(
        label: Copy.of(context).gallerySampleGrade,
        options: _grades,
        value: 'a',
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppRadioGroup<String>(
        label: Copy.of(context).gallerySampleGrade,
        options: _grades,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppRadioGroup<String>(
        label: Copy.of(context).gallerySampleGrade,
        options: _grades,
        value: 'b',
        framed: false,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppRadioGroup<String>(
        label: Copy.of(context).gallerySampleGrade,
        options: _grades,
        value: 'b',
        direction: Axis.horizontal,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppCheckboxGroup<String>(
        label: Copy.of(context).gallerySampleTags,
        options: _tags,
        value: const <String>{'water'},
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppMultiChoiceField<String>(
        label: Copy.of(context).gallerySampleTags,
        options: _tags,
        value: const <String>{},
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppMultiChoiceField<String>(
        label: Copy.of(context).gallerySampleTags,
        options: _tags,
        value: const <String>{'water', 'steam'},
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppSwitchTile(
        title: Copy.of(context).gallerySampleLocation,
        value: true,
        onChanged: (_) {},
      ),
      AppSwitchTile(
        title: Copy.of(context).gallerySampleLocation,
        value: false,
        enabled: false,
        onChanged: (_) {},
      ),
      AppSwitchTile.checkbox(
        title: Copy.of(context).gallerySampleLocation,
        value: true,
        onChanged: (_) {},
      ),
      AppSwitchTile.checkbox(
        title: Copy.of(context).gallerySampleLocation,
        value: true,
        dense: true,
        controlFirst: true,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x2),
      AppSwitchTile(
        title: Copy.of(context).gallerySampleLocation,
        description: Copy.of(context).gallerySampleStampCapture,
        value: true,
        dense: true,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      ProviderScope(
        overrides: <Override>[
          fieldEditorBindingsProvider.overrideWithValue(_galleryBindings),
        ],
        child: const FieldEditor(
          field: (
            fieldKey: 'serial',
            label: 'Serial',
            type: 'text',
            options: <Object>[],
            helpText: null,
            unit: null,
            validation: <String, Object?>{},
          ),
          value: FieldValue(fieldKey: 'serial', value: 'ABB-1'),
          onChanged: _ignoreFieldValue,
        ),
      ),
      const SizedBox(height: Space.x4),
      AppForm(
        fields: <Widget>[
          AppTextField(
            label: Copy.of(context).gallerySampleName,
            controller: _formName,
            errorText: localCopy.outOfRange,
          ),
        ],
        submitLabel: localCopy.save,
        onSubmit: () async => true,
      ),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _containers() {
    final LocalizedCopy localCopy = Copy.of(context);

    final double edge = AppConstants.images.thumbnailEdge.toDouble();
    return <Widget>[
      AppSectionHeader(title: localCopy.galleryContainers),
      // Collapsible headings, closed and open.
      AppSectionHeader(
        title: localCopy.galleryContainers,
        expanded: false,
        onToggle: _noop,
      ),
      AppSectionHeader(
        title: localCopy.galleryContainers,
        expanded: true,
        onToggle: _noop,
      ),
      AppCard(child: Text(localCopy.galleryContainers)),
      const SizedBox(height: Space.x4),
      AppCard(onTap: _noop, child: Text(localCopy.galleryContainers)),
      const SizedBox(height: Space.x4),
      AppListTile(
        title: Copy.of(context).gallerySampleBoilerA,
        subtitle: localCopy.recordsCount(2),
        status: const AppStatusPill(status: RecordStatus.draft),
        onTap: _noop,
        onLongPress: _noop,
      ),
      AppListTile(
        title: Copy.of(context).gallerySampleBoilerB,
        subtitle: Copy.of(context).gallerySampleBesideList,
        current: true,
        onTap: _noop,
      ),
      AppListTile(
        title: Copy.of(context).gallerySampleBoilerA,
        dense: true,
        selected: true,
        status: const AppStatusPill.badge(status: RecordStatus.captured),
        onTap: _noop,
        onLongPress: _noop,
      ),
      const SizedBox(height: Space.x4),
      // A header that scrolls away above a bounded, lazy list.
      SizedBox(
        height: Sizes.minTapTarget * 4,
        child: AppListViewport(
          header: AppSectionHeader(title: localCopy.galleryContainers),
          body: ListView(
            children: <Widget>[
              for (final String title in <String>[
                Copy.of(context).gallerySampleBoilerA,
                Copy.of(context).gallerySampleBoilerB,
              ])
                AppListTile(title: title, onTap: _noop),
            ],
          ),
        ),
      ),
      const SizedBox(height: Space.x4),
      AppChip(label: Copy.of(context).gallerySampleWater),
      const SizedBox(height: Space.x2),
      AppChip(
        label: Copy.of(context).gallerySampleWater,
        selected: true,
        onTap: _noop,
      ),
      const SizedBox(height: Space.x2),
      AppChip(label: Copy.of(context).gallerySampleWater, onDismiss: _noop),
      const SizedBox(height: Space.x4),
      AppChipRow(
        chips: <AppChip>[
          AppChip(label: Copy.of(context).gallerySampleWater),
          AppChip(label: Copy.of(context).gallerySampleSteam),
          AppChip(label: Copy.of(context).gallerySampleGas),
        ],
      ),
      const SizedBox(height: Space.x2),
      AppChipRow(
        scrollable: true,
        chips: <AppChip>[
          AppChip(label: Copy.of(context).gallerySampleWater),
          AppChip(label: Copy.of(context).gallerySampleSteam),
          AppChip(label: Copy.of(context).gallerySampleGas),
        ],
      ),
      const SizedBox(height: Space.x4),
      Wrap(
        spacing: Space.x2,
        runSpacing: Space.x2,
        children: <Widget>[
          for (final RecordStatus status in RecordStatus.values)
            AppStatusPill(status: status),
        ],
      ),
      const SizedBox(height: Space.x2),
      Wrap(
        spacing: Space.x2,
        runSpacing: Space.x2,
        children: <Widget>[
          for (final RecordStatus status in RecordStatus.values)
            AppStatusPill.badge(status: status),
        ],
      ),
      const SizedBox(height: Space.x4),
      Wrap(
        spacing: Space.x3,
        runSpacing: Space.x3,
        children: <Widget>[
          AppPhotoThumb(
            photo: const PhotoAsset(sha256: 'abc', photoType: PhotoType.front),
            size: edge,
            onTap: _noop,
            onLongPress: _noop,
          ),
          AppPhotoThumb(
            photo: const PhotoAsset(
              sha256: 'abc',
              photoType: PhotoType.serial,
              hasCaption: true,
            ),
            size: edge,
            selected: true,
            onTap: _noop,
            onLongPress: _noop,
          ),
          AppPhotoThumb(
            photo: const PhotoAsset(
              sha256: 'dead',
              thumbPath: '/missing.jpg',
              photoType: PhotoType.front,
            ),
            size: edge,
          ),
          AppPhotoThumb(
            photo: const PhotoAsset(sha256: 'tick', hasCaption: true),
            size: edge,
            selected: true,
            onTap: _noop,
            onSelectedChanged: (bool _) {},
            onRemove: _noop,
          ),
          AppPhotoThumb(
            photo: const PhotoAsset(sha256: 'pick'),
            size: edge,
            onTap: _noop,
            onSelectedChanged: (bool _) {},
            onRemove: _noop,
          ),
          AppPhotoThumb(
            photo: const PhotoAsset(sha256: 'turn', thumbPath: '/turned.jpg'),
            size: edge,
            quarterTurns: 1,
          ),
          AppPhotoThumb(
            photo: PhotoAsset(
              sha256: 'bytes',
              thumbBytes: _photoBytes,
              hasCaption: true,
            ),
            size: edge,
            onTap: _noop,
            onSelectedChanged: (bool _) {},
            onRemove: _noop,
          ),
        ],
      ),
      const SizedBox(height: Space.x4),
      // A stored photo draws from the thumbnail cache. The gallery stores
      // none, so each one shows Missing photo.
      ProviderScope(
        overrides: <Override>[
          photoThumbnailsProvider.overrideWithValue(_galleryThumbnails),
        ],
        child: Wrap(
          spacing: Space.x3,
          runSpacing: Space.x3,
          children: <Widget>[
            RecordThumb(
              sha256: 'abc',
              storagePath: 'projects/boiler/photos/front.jpg',
              size: edge,
              onTap: _noop,
              onLongPress: _noop,
            ),
            RecordThumb(
              sha256: 'serial',
              storagePath: 'projects/boiler/photos/serial.jpg',
              size: edge,
              hasCaption: true,
              selected: true,
              onTap: _noop,
              onLongPress: _noop,
            ),
          ],
        ),
      ),
      const SizedBox(height: Space.x4),
      AppInkPicker(
        ink: _ink,
        size: _inkSize,
        onInk: (MarkupInk ink) => setState(() => _ink = ink),
        onSize: (int size) => setState(() => _inkSize = size),
      ),
      const SizedBox(height: Space.x4),
      // A live transcript: settled lines, then the words still arriving.
      SizedBox(
        height: Space.x12 * 4,
        child: AppTranscriptView(
          paragraphs: <String>[
            localCopy.gallerySampleBoilerA,
            localCopy.gallerySampleStampCapture,
            localCopy.gallerySampleBesideList,
          ],
          tentative: localCopy.gallerySampleSteam,
          live: true,
        ),
      ),
      const SizedBox(height: Space.x4),
      const SizedBox(
        height: Space.x12 * 2,
        child: AppTranscriptView(paragraphs: <String>[]),
      ),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _states() {
    final LocalizedCopy localCopy = Copy.of(context);

    return <Widget>[
      AppSectionHeader(title: localCopy.galleryStates),
      AppEmptyState(
        icon: AppIcons.empty,
        headline: localCopy.emptyHeadline,
        message: localCopy.emptyMessage,
        actionLabel: localCopy.tryAgain,
        onAction: _noop,
      ),
      // The icon is the next action, with no button under it.
      AppEmptyState(
        icon: AppIcons.addPhoto,
        headline: localCopy.captureNoPhotosHeadline,
        message: localCopy.captureNoPhotosMessage,
        onIconTap: _noop,
        iconLabel: localCopy.captureAddPhoto,
      ),
      const AppErrorState(failure: NetworkFailure(), onRetry: _noop),
      const AppSkeleton(shape: SkeletonShape.list, count: 2),
      const SizedBox(height: Space.x4),
      const AppSkeleton(shape: SkeletonShape.card, count: 1),
      const SizedBox(height: Space.x4),
      const AppSkeleton(shape: SkeletonShape.detail, count: 1),
      const SizedBox(height: Space.x4),
      const Align(alignment: Alignment.centerLeft, child: AppSkeleton.inline()),
      AsyncValueView<String>(
        value: const AsyncLoading<String>(),
        data: (String name) => Text(name),
      ),
      AsyncValueView<String>(
        value: const AsyncError<String>('missing', StackTrace.empty),
        data: (String name) => Text(name),
        onRetry: _noop,
      ),
      AsyncValueView<List<String>>(
        value: const AsyncData<List<String>>(<String>[]),
        isEmpty: (List<String> rows) => rows.isEmpty,
        data: (List<String> rows) => Text(rows.join()),
      ),
      AsyncValueView<String>(
        value: AsyncData<String>(Copy.of(context).gallerySampleBoilerA),
        data: (String name) => Text(name),
      ),
      ErrorBoundary(child: Text(localCopy.galleryStates)),
      const AppProgressSteps(
        steps: <ProgressStep>[
          ProgressStep(label: 'Read text', state: StepState.done),
          ProgressStep(label: 'Write values', state: StepState.running),
          ProgressStep(label: 'Save record', state: StepState.waiting),
          ProgressStep(
            label: 'Upload',
            state: StepState.failed,
            detail: 'The file could not be read.',
          ),
        ],
      ),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _feedback() {
    final LocalizedCopy localCopy = Copy.of(context);

    return <Widget>[
      AppSectionHeader(title: localCopy.galleryFeedback),
      AppBanner(
        message: localCopy.unsavedChanges,
        icon: AppIcons.offline,
        tone: SnackTone.warning,
        onDismiss: _noop,
      ),
      const SizedBox(height: Space.x4),
      AppBanner(
        message: localCopy.unsavedChanges,
        icon: AppIcons.info,
        tone: SnackTone.info,
      ),
      const SizedBox(height: Space.x4),
      AppSnackbar(
        message: localCopy.save,
        tone: SnackTone.success,
        undoLabel: localCopy.undo,
        onUndo: _noop,
      ),
      const SizedBox(height: Space.x2),
      AppSnackbar(message: localCopy.failed, tone: SnackTone.error),
      const SizedBox(height: Space.x4),
      AppDialog.confirm(
        title: localCopy.discardChangesTitle,
        message: localCopy.unsavedChanges,
        confirmLabel: localCopy.discard,
        destructive: true,
        onConfirm: _noop,
        onCancel: _noop,
      ),
      const SizedBox(height: Space.x4),
      AppDialog.alert(
        title: localCopy.save,
        message: localCopy.notDetected,
        onConfirm: _noop,
      ),
      const SizedBox(height: Space.x4),
      SizedBox(
        height: Space.x12 * 8,
        child: AppPanelDialog(
          title: localCopy.feedbackGive,
          child: Text(localCopy.galleryFeedback, style: AppText.body),
        ),
      ),
      const SizedBox(height: Space.x4),
      SizedBox(
        height: Space.x12 * 5,
        child: AppBottomSheet(
          title: Copy.of(context).gallerySampleGrade,
          child: Text(localCopy.galleryFeedback, style: AppText.body),
        ),
      ),
    ];
  }

  static void _noop() {}

  static void _ignoreAnchor(Rect _) {}
}

void _ignoreFieldValue(FieldValue _) {}

/// Serves no stored photo, so the gallery's [RecordThumb]s show the missing
/// state on every platform without reading the storage root.
final PhotoThumbnails _galleryThumbnails = PhotoThumbnails.fake(
  const <String, String>{},
);

const FieldEditorBindings _galleryBindings = (
  kindOf: _galleryKind,
  validate: _galleryValidate,
  normalise: _galleryNormalise,
);

String _galleryKind(String _) => 'appTextField';

Result<void> _galleryValidate({
  required String type,
  required Object? value,
  required List<Object> options,
  required Map<String, Object?> validation,
}) {
  return const Success<void>(null);
}

Object? _galleryNormalise({
  required String type,
  required Object? value,
  required List<Object> options,
  required Map<String, Object?> validation,
}) {
  return value;
}

/// A diagonal grey gradient, encoded as PNG.
Uint8List _gradientPhoto() {
  final img.Image pixels = img.Image(width: 48, height: 64);
  for (final img.Pixel pixel in pixels) {
    final int shade = 64 + (pixel.x + pixel.y) * 2;
    pixel.setRgb(shade, shade, shade);
  }
  return img.encodePng(pixels);
}
