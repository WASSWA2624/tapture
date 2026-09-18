import 'dart:io';

import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/color_swatches.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/surface_levels.dart';
import 'package:tapture/app/theme/type_ramp.dart';
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
import 'package:tapture/core/widgets/gallery/widget_gallery_screen.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import 'golden_harness.dart';

final RegExp _widgetClass = RegExp(
  r'^class ([A-Z][A-Za-z0-9]*)(?:<[^>]+>)? extends '
  r'(?:Stateless|Stateful|Consumer)Widget\b',
);

void main() {
  for (final String name in _stems()) {
    testWidgets('$name matches light, dark and outdoor baselines', (
      WidgetTester tester,
    ) async {
      final TextEditingController field = TextEditingController(text: 'Ada');
      addTearDown(field.dispose);
      await expectGolden(tester, _sample(name, field), name);
    });
  }

  test(
    'every public catalogue widget has light, dark and outdoor baselines',
    () {
      final Directory goldens = Directory('test/design_system/goldens');
      final List<String> missing = <String>[];
      for (final String name in _stems()) {
        for (final String mode in <String>['light', 'dark', 'outdoor']) {
          final String file = '${name}_$mode.png';
          if (!File('${goldens.path}/$file').existsSync()) {
            missing.add(file);
          }
        }
      }
      expect(
        missing,
        isEmpty,
        reason:
            'catalogue widgets with no golden: ${missing.join(', ')} '
            '(FE-TEST-02)',
      );
    },
  );
}

List<String> _stems() {
  final Set<String> stems = <String>{
    'color_swatches',
    'type_ramp',
    'surface_levels',
  };
  for (final String name in _publicWidgets()) {
    stems.add(_stemFor(name));
  }
  final List<String> sorted = stems.toList()..sort();
  return sorted;
}

String _stemFor(String className) {
  if (className == 'WidgetGalleryScreen') {
    return 'gallery_index';
  }
  return className
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (Match match) => '_${match[0]!.toLowerCase()}',
      )
      .substring(1);
}

List<String> _publicWidgets() {
  final Directory root = Directory('lib/core/widgets');
  final List<String> names = <String>[];
  for (final File file
      in root
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (File file) =>
                file.path.endsWith('.dart') &&
                file.uri.pathSegments.last.split('.').length == 2,
          )) {
    for (final String line in file.readAsLinesSync()) {
      final Match? match = _widgetClass.firstMatch(line.trimLeft());
      if (match != null) {
        names.add(match.group(1)!);
      }
    }
  }
  names.sort();
  return names;
}

Widget _sample(String name, TextEditingController field) {
  switch (name) {
    case 'app_banner':
      return const AppBanner(
        message: Copy.unsavedChanges,
        icon: Icons.wifi_off,
        tone: SnackTone.warning,
      );
    case 'app_bottom_sheet':
      return const AppBottomSheet(
        title: 'Grade',
        child: Text(Copy.galleryFeedback),
      );
    case 'app_brand_lockup':
      return const AppBrandLockup();
    case 'app_button':
      return const AppButton(label: Copy.save, onPressed: _noop);
    case 'app_card':
      return const AppCard(child: Text(Copy.galleryContainers));
    case 'app_chip':
      return const AppChip(label: 'Water', selected: true, onTap: _noop);
    case 'app_chip_row':
      return const AppChipRow(
        chips: <AppChip>[
          AppChip(label: 'Water'),
          AppChip(label: 'Steam'),
          AppChip(label: 'Gas'),
        ],
      );
    case 'app_choice_field':
      return const AppChoiceField<String>(
        label: 'Grade',
        options: _grades,
        value: 'a',
        onChanged: _ignoreString,
      );
    case 'app_date_field':
      return AppDateField(
        label: 'When',
        value: _stamp,
        clock: FixedClock(_stamp),
        onChanged: _ignoreDate,
      );
    case 'app_dialog':
      return AppDialog.alert(
        title: Copy.save,
        message: Copy.notDetected,
        onConfirm: _noop,
      );
    case 'app_empty_state':
      return const AppEmptyState(
        icon: Icons.inbox_outlined,
        headline: Copy.emptyHeadline,
        message: Copy.emptyMessage,
        actionLabel: Copy.tryAgain,
        onAction: _noop,
      );
    case 'app_floating_button':
      return const SizedBox(
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
      );
    case 'app_error_state':
      return const AppErrorState(failure: NetworkFailure(), onRetry: _noop);
    case 'app_form':
      return AppForm(
        fields: <Widget>[AppTextField(label: 'Name', controller: field)],
        submitLabel: Copy.save,
        onSubmit: _submit,
      );
    case 'app_icon_button':
      return const AppIconButton(
        icon: Icons.search,
        semanticLabel: Copy.galleryFields,
        tooltip: Copy.galleryFields,
        onPressed: _noop,
      );
    case 'app_list_tile':
      return const AppListTile(
        title: 'Boiler A',
        status: AppStatusPill(status: RecordStatus.draft),
        onTap: _noop,
        onLongPress: _noop,
      );
    case 'app_multi_choice_field':
      return const AppMultiChoiceField<String>(
        label: 'Tags',
        options: _grades,
        value: <String>{'a'},
        onChanged: _ignoreSet,
      );
    case 'app_number_field':
      return const AppNumberField(label: 'Count', onChanged: _ignoreNum);
    case 'app_overflow_menu':
      return const AppOverflowMenu(
        key: ValueKey<String>('app-overflow'),
        items: <AppOverflowAction>[
          AppOverflowAction(
            icon: Icons.save_outlined,
            label: Copy.save,
            onTap: _noop,
          ),
        ],
      );
    case 'app_panel_dialog':
      return const AppPanelDialog(
        title: Copy.save,
        onClose: _noop,
        child: Text(Copy.galleryFeedback),
      );
    case 'app_page':
      return const AppPage(
        title: Copy.galleryTitle,
        overflow: <AppOverflowAction>[
          AppOverflowAction(label: Copy.save, onTap: _noop),
        ],
        body: Text(Copy.save),
      );
    case 'app_photo_thumb':
      return AppPhotoThumb(
        photo: const PhotoAsset(sha256: 'abc', photoType: PhotoType.front),
        size: AppConstants.images.thumbnailEdge.toDouble(),
      );
    case 'app_primary_action':
      return const AppPrimaryAction(label: Copy.save, onPressed: _noop);
    case 'app_radio_group':
      return const AppRadioGroup<String>(
        label: 'Grade',
        options: _grades,
        value: 'a',
        onChanged: _ignoreText,
      );
    case 'app_progress_steps':
      return const AppProgressSteps(
        steps: <ProgressStep>[
          ProgressStep(label: 'Read text', state: StepState.done),
          ProgressStep(label: 'Write values', state: StepState.running),
          ProgressStep(label: 'Save record', state: StepState.waiting),
          ProgressStep(label: 'Upload', state: StepState.failed),
        ],
      );
    case 'app_search_field':
      return AppSearchField(hint: 'Search records', onChanged: _ignoreText);
    case 'app_section_header':
      return const AppSectionHeader(title: Copy.galleryContainers);
    case 'app_skeleton':
      return const AppSkeleton(shape: SkeletonShape.list, count: 2);
    case 'app_snackbar':
      return const AppSnackbar(message: Copy.save, tone: SnackTone.success);
    case 'app_status_pill':
      return const AppStatusPill(status: RecordStatus.captured);
    case 'app_switch_tile':
      return const AppSwitchTile(
        title: 'GPS',
        value: true,
        onChanged: _ignoreBool,
      );
    case 'app_text_field':
      return AppTextField(label: 'Name', controller: field);
    case 'async_value_view':
      return AsyncValueView<String>(
        value: const AsyncData<String>('Ada'),
        data: (String value) => Text(value),
      );
    case 'color_swatches':
      return const ColorSwatches();
    case 'content_constraint':
      return const ContentConstraint(child: Text(Copy.galleryLayout));
    case 'dictation_status':
      return const DictationStatus(
        phase: DictationPhase.listening,
        heard: 'The pump leaks at night',
      );
    case 'error_boundary':
      return const ErrorBoundary(child: Text(Copy.save));
    case 'gallery_index':
      return const WidgetGalleryScreen();
    case 'keep_focused_visible':
      return KeepFocusedVisible(
        child: AppTextField(label: 'Name', controller: field),
      );
    case 'responsive_builder':
      return ResponsiveBuilder(
        compact: (BuildContext context) {
          return const Text(Copy.galleryCompact);
        },
      );
    case 'surface_levels':
      return const SurfaceLevels();
    case 'type_ramp':
      return const TypeRamp();
    default:
      throw StateError('no golden sample for $name (FE-TEST-02)');
  }
}

const List<Choice<String>> _grades = <Choice<String>>[
  Choice<String>('a', 'A'),
  Choice<String>('b', 'B'),
  Choice<String>('c', 'C'),
];

final DateTime _stamp = DateTime.utc(2026, 9, 17, 12);

void _noop() {}

void _ignoreAnchor(Rect _) {}

void _ignoreBool(bool value) {}

void _ignoreNum(num? value) {}

void _ignoreString(String? value) {}

void _ignoreText(String value) {}

void _ignoreDate(DateTime? value) {}

void _ignoreSet(Set<String> value) {}

Future<void> _submit() async {}
