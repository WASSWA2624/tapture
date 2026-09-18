import 'dart:math' as math;

import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/color_swatches.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/app/theme/surface_levels.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/app/theme/type_ramp.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_brand_lockup.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_floating_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/error_boundary.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_panel_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_number_field.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/fields/dictation_phase.dart';
import 'package:tapture/core/widgets/fields/dictation_status.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/forms/keep_focused_visible.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';
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
  static final FixedClock _clock = FixedClock(DateTime.utc(2026, 9, 17, 12));
  static const List<Choice<AppThemeMode>> _themes = <Choice<AppThemeMode>>[
    Choice<AppThemeMode>(AppThemeMode.light, Copy.galleryLight),
    Choice<AppThemeMode>(AppThemeMode.dark, Copy.galleryDark),
    Choice<AppThemeMode>(AppThemeMode.outdoor, Copy.galleryOutdoor),
  ];
  static const List<Choice<SizeClass>> _widths = <Choice<SizeClass>>[
    Choice<SizeClass>(SizeClass.compact, Copy.galleryCompact),
    Choice<SizeClass>(SizeClass.medium, Copy.galleryMedium),
    Choice<SizeClass>(SizeClass.expanded, Copy.galleryExpanded),
  ];
  static const List<Choice<double>> _scales = <Choice<double>>[
    Choice<double>(1, Copy.galleryScale100),
    Choice<double>(2, Copy.galleryScale200),
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
                  title: Copy.galleryTitle,
                  leading: AppBrandLockup(
                    showName: false,
                    inverted: _theme != AppThemeMode.dark,
                  ),
                  actions: const <Widget>[
                    AppIconButton(
                      icon: Icons.contrast,
                      semanticLabel: Copy.galleryTheme,
                      tooltip: Copy.galleryTheme,
                      onPressed: _noop,
                    ),
                  ],
                  overflow: const <AppOverflowAction>[
                    AppOverflowAction(
                      icon: Icons.save_outlined,
                      label: Copy.save,
                      onTap: _noop,
                    ),
                  ],
                  footer: AppPrimaryAction(
                    label: Copy.save,
                    caption: Copy.recordsCount(2),
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
    return <Widget>[
      AppChoiceField<AppThemeMode>(
        label: Copy.galleryTheme,
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
        label: Copy.galleryWidth,
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
        label: Copy.galleryTextScale,
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
                    const AppButton(label: Copy.save, onPressed: _noop),
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
                        const AppButton(label: Copy.save, onPressed: _noop),
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
    return <Widget>[
      const AppSectionHeader(title: Copy.galleryTokens),
      const SizedBox(height: Space.x12 * 6, child: ColorSwatches()),
      const SizedBox(height: Space.x4),
      const SizedBox(height: Space.x12 * 8, child: TypeRamp()),
      const SizedBox(height: Space.x4),
      const SizedBox(height: Space.x12 * 6, child: SurfaceLevels()),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _layout() {
    return <Widget>[
      const AppSectionHeader(title: Copy.galleryLayout),
      const AppBrandLockup(),
      const SizedBox(height: Space.x3),
      const ContentConstraint(
        child: AppCard(child: Text(Copy.galleryLayout, style: AppText.body)),
      ),
      const SizedBox(height: Space.x4),
      ResponsiveBuilder(
        compact: (BuildContext context) {
          return const AppCard(
            child: Text(Copy.galleryCompact, style: AppText.body),
          );
        },
        medium: (BuildContext context) {
          return const AppCard(
            child: Text(Copy.galleryMedium, style: AppText.body),
          );
        },
        expanded: (BuildContext context) {
          return const AppCard(
            child: Text(Copy.galleryExpanded, style: AppText.body),
          );
        },
      ),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _buttons() {
    return <Widget>[
      const AppSectionHeader(title: Copy.galleryButtons),
      for (final AppButtonVariant variant
          in AppButtonVariant.values) ...<Widget>[
        Wrap(
          spacing: Space.x2,
          runSpacing: Space.x2,
          children: <Widget>[
            AppButton(label: Copy.save, variant: variant, onPressed: _noop),
            AppButton(
              label: Copy.save,
              variant: variant,
              busy: true,
              onPressed: _noop,
            ),
            AppButton(label: Copy.save, variant: variant),
            AppButton(
              label: Copy.save,
              variant: variant,
              icon: Icons.check,
              onPressed: _noop,
            ),
          ],
        ),
        const SizedBox(height: Space.x3),
      ],
      const Row(
        children: <Widget>[
          AppIconButton(
            icon: Icons.search,
            semanticLabel: Copy.galleryFields,
            tooltip: Copy.galleryFields,
            onPressed: _noop,
          ),
          SizedBox(width: Space.x2),
          AppIconButton(
            icon: Icons.mic,
            semanticLabel: Copy.dictationListening,
            tooltip: Copy.dictationListening,
            selected: true,
            onPressed: _noop,
          ),
        ],
      ),
      const SizedBox(height: Space.x3),
      const AppOverflowMenu(
        key: ValueKey<String>('app-overflow'),
        items: <AppOverflowAction>[
          AppOverflowAction(
            icon: Icons.save_outlined,
            label: Copy.save,
            onTap: _noop,
          ),
        ],
      ),
      const SizedBox(height: Space.x3),
      const SizedBox(
        height: Sizes.minTapTarget * 3,
        child: Stack(
          children: <Widget>[
            AppFloatingButton(
              icon: Icons.feedback_outlined,
              label: Copy.feedback,
              hint: Copy.feedbackButtonHint,
              onPressed: _ignoreAnchor,
            ),
          ],
        ),
      ),
      const SizedBox(height: Space.x3),
      const AppPrimaryAction(label: Copy.save),
      const SizedBox(height: Space.x3),
      const AppPrimaryAction(label: Copy.save, busy: true, onPressed: _noop),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _fields() {
    return <Widget>[
      const AppSectionHeader(title: Copy.galleryFields),
      KeepFocusedVisible(
        child: AppTextField(label: 'Name', controller: _empty, hint: 'Name'),
      ),
      const SizedBox(height: Space.x4),
      AppTextField(label: 'Name', controller: _filled, clearable: true),
      const SizedBox(height: Space.x4),
      AppTextField(
        label: 'Name',
        controller: _error,
        errorText: Copy.outOfRange,
      ),
      const SizedBox(height: Space.x4),
      AppTextField(label: 'Name', controller: _empty, enabled: false),
      const SizedBox(height: Space.x4),
      AppTextField(
        label: 'Caption',
        controller: _multiline,
        maxLines: 4,
        maxLength: 80,
      ),
      const SizedBox(height: Space.x2),
      const DictationStatus(phase: DictationPhase.starting),
      const SizedBox(height: Space.x2),
      const DictationStatus(
        phase: DictationPhase.listening,
        heard: 'The pump leaks at night',
      ),
      const SizedBox(height: Space.x4),
      AppNumberField(label: 'Count', min: 0, max: 10, onChanged: (_) {}),
      const SizedBox(height: Space.x4),
      AppNumberField(label: 'Count', enabled: false, onChanged: (_) {}),
      const SizedBox(height: Space.x4),
      AppDateField(
        label: 'When',
        mode: DateFieldMode.date,
        clock: _clock,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppDateField(
        label: 'When',
        mode: DateFieldMode.time,
        value: _clock.nowUtc(),
        clock: _clock,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppDateField(
        label: 'When',
        mode: DateFieldMode.dateTime,
        value: _clock.nowUtc(),
        autoFilled: true,
        clock: _clock,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppSearchField(hint: Copy.search, resultCount: 2, onChanged: (_) {}),
      const SizedBox(height: Space.x4),
      AppChoiceField<String>(
        label: 'Grade',
        options: _grades,
        value: 'a',
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppChoiceField<String>(
        label: 'Grade',
        options: _grades,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppChoiceField<String>(
        label: 'Fuel',
        options: _tags,
        value: 'water',
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppRadioGroup<String>(
        label: 'Grade',
        options: _grades,
        value: 'a',
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppRadioGroup<String>(
        label: 'Grade',
        options: _grades,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppRadioGroup<String>(
        label: 'Grade',
        options: _grades,
        value: 'b',
        direction: Axis.horizontal,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppMultiChoiceField<String>(
        label: 'Tags',
        options: _tags,
        value: const <String>{},
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppMultiChoiceField<String>(
        label: 'Tags',
        options: _tags,
        value: const <String>{'water', 'steam'},
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppSwitchTile(title: 'GPS', value: true, onChanged: (_) {}),
      AppSwitchTile(
        title: 'GPS',
        value: false,
        enabled: false,
        onChanged: (_) {},
      ),
      AppSwitchTile.checkbox(title: 'GPS', value: true, onChanged: (_) {}),
      const SizedBox(height: Space.x2),
      AppSwitchTile(
        title: 'GPS',
        description: 'Stamp each capture',
        value: true,
        dense: true,
        onChanged: (_) {},
      ),
      const SizedBox(height: Space.x4),
      AppForm(
        fields: <Widget>[
          AppTextField(
            label: 'Name',
            controller: _formName,
            errorText: Copy.outOfRange,
          ),
        ],
        submitLabel: Copy.save,
        onSubmit: () async {},
      ),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _containers() {
    final double edge = AppConstants.images.thumbnailEdge.toDouble();
    return <Widget>[
      const AppSectionHeader(title: Copy.galleryContainers),
      const AppCard(child: Text(Copy.galleryContainers)),
      const SizedBox(height: Space.x4),
      const AppCard(onTap: _noop, child: Text(Copy.galleryContainers)),
      const SizedBox(height: Space.x4),
      AppListTile(
        title: 'Boiler A',
        subtitle: Copy.recordsCount(2),
        status: const AppStatusPill(status: RecordStatus.draft),
        onTap: _noop,
        onLongPress: _noop,
      ),
      const AppListTile(
        title: 'Boiler A',
        dense: true,
        selected: true,
        status: AppStatusPill.badge(status: RecordStatus.captured),
        onTap: _noop,
        onLongPress: _noop,
      ),
      const SizedBox(height: Space.x4),
      const AppChip(label: 'Water'),
      const SizedBox(height: Space.x2),
      const AppChip(label: 'Water', selected: true, onTap: _noop),
      const SizedBox(height: Space.x2),
      const AppChip(label: 'Water', onDismiss: _noop),
      const SizedBox(height: Space.x4),
      const AppChipRow(
        chips: <AppChip>[
          AppChip(label: 'Water'),
          AppChip(label: 'Steam'),
          AppChip(label: 'Gas'),
        ],
      ),
      const SizedBox(height: Space.x2),
      const AppChipRow(
        scrollable: true,
        chips: <AppChip>[
          AppChip(label: 'Water'),
          AppChip(label: 'Steam'),
          AppChip(label: 'Gas'),
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
        ],
      ),
      const SizedBox(height: Space.x6),
    ];
  }

  List<Widget> _states() {
    return <Widget>[
      const AppSectionHeader(title: Copy.galleryStates),
      const AppEmptyState(
        icon: Icons.inbox_outlined,
        headline: Copy.emptyHeadline,
        message: Copy.emptyMessage,
        actionLabel: Copy.tryAgain,
        onAction: _noop,
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
        value: const AsyncData<String>('Boiler A'),
        data: (String name) => Text(name),
      ),
      const ErrorBoundary(child: Text(Copy.galleryStates)),
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
    return <Widget>[
      const AppSectionHeader(title: Copy.galleryFeedback),
      const AppBanner(
        message: Copy.unsavedChanges,
        icon: Icons.wifi_off,
        tone: SnackTone.warning,
        onDismiss: _noop,
      ),
      const SizedBox(height: Space.x4),
      const AppBanner(
        message: Copy.unsavedChanges,
        icon: Icons.info_outline,
        tone: SnackTone.info,
      ),
      const SizedBox(height: Space.x4),
      const AppSnackbar(
        message: Copy.save,
        tone: SnackTone.success,
        undoLabel: Copy.undo,
        onUndo: _noop,
      ),
      const SizedBox(height: Space.x2),
      const AppSnackbar(message: Copy.failed, tone: SnackTone.error),
      const SizedBox(height: Space.x4),
      const AppDialog.confirm(
        title: Copy.discardChangesTitle,
        message: Copy.unsavedChanges,
        confirmLabel: Copy.discard,
        destructive: true,
        onConfirm: _noop,
        onCancel: _noop,
      ),
      const SizedBox(height: Space.x4),
      AppDialog.alert(
        title: Copy.save,
        message: Copy.notDetected,
        onConfirm: _noop,
      ),
      const SizedBox(height: Space.x4),
      const SizedBox(
        height: Space.x12 * 8,
        child: AppPanelDialog(
          title: Copy.feedbackGive,
          child: Text(Copy.galleryFeedback, style: AppText.body),
        ),
      ),
      const SizedBox(height: Space.x4),
      const SizedBox(
        height: Space.x12 * 5,
        child: AppBottomSheet(
          title: 'Grade',
          child: Text(Copy.galleryFeedback, style: AppText.body),
        ),
      ),
    ];
  }

  static void _noop() {}

  static void _ignoreAnchor(Rect _) {}
}
