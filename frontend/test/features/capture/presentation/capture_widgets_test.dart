import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/barcode/barcode_scanner_service.dart';
import 'package:tapture/core/camera/camera.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/document_correction.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/audio_recorder.dart';
import 'package:tapture/features/capture/presentation/barcode_continuous_mode.dart';
import 'package:tapture/features/capture/presentation/barcode_scanner_screen.dart';
import 'package:tapture/features/capture/presentation/camera_controls.dart';
import 'package:tapture/features/capture/presentation/camera_permission_gate.dart';
import 'package:tapture/features/capture/presentation/camera_view.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_manual_form.dart';
import 'package:tapture/features/capture/presentation/capture_screen.dart';
import 'package:tapture/features/capture/presentation/document_mode.dart';
import 'package:tapture/features/capture/presentation/document_picker.dart';
import 'package:tapture/features/capture/presentation/gallery_picker.dart';
import 'package:tapture/features/capture/presentation/inline_fields_section.dart';
import 'package:tapture/features/capture/presentation/mic_permission_gate.dart';
import 'package:tapture/features/capture/presentation/photo_crop_screen.dart';
import 'package:tapture/features/capture/presentation/photo_multi_select.dart';
import 'package:tapture/features/capture/presentation/photo_reorder.dart';
import 'package:tapture/features/capture/presentation/photo_tray.dart';
import 'package:tapture/features/capture/presentation/photo_type_sheet.dart';
import 'package:tapture/features/capture/presentation/photo_viewer_screen.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/capture/presentation/voice_input_button.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart' show SettingsStore;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_barcode_scanner_service.dart';
import '../../../support/fakes/fake_photo_repository.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../../templates/fakes/fake_template_repository.dart';

AppIconButton _icon(WidgetTester tester, String tooltip) {
  return tester.widget<AppIconButton>(
    find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(AppIconButton),
    ),
  );
}

Widget wrap(Widget child, {List<Override> overrides = const <Override>[]}) {
  return ProviderScope(
    overrides: <Override>[
      fieldEditorBindingsProvider.overrideWithValue(
        templateFieldEditorBindings,
      ),
      ...overrides,
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

PhotoDraft draft(String id, {String type = 'other', int order = 0}) {
  return PhotoDraft(
    id: id,
    projectId: 'p1',
    relativePath: 'photos/$id.jpg',
    sha256: 'h$id',
    photoType: type,
    sortOrder: order,
  );
}

void main() {
  for (final bool populated in <bool>[false, true]) {
    testWidgets('composer tray hides only duplicate intake: $populated', (
      tester,
    ) async {
      int added = 0;
      String? selected;
      String? opened;
      await tester.pumpWidget(
        wrap(
          PhotoTray(
            photos: populated ? <PhotoDraft>[draft('a')] : const <PhotoDraft>[],
            showAddAction: false,
            onAdd: () => added++,
            onTap: (photo) => opened = photo.id,
            onLongPress: (photo) => selected = photo.id,
          ),
        ),
      );
      expect(find.byTooltip(Copy.captureAddPhoto), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('empty-state-icon-action')),
        findsNothing,
      );
      if (populated) {
        await tester.tap(find.byKey(const ValueKey<String>('photo-thumb-a')));
        await tester.tap(_selectTarget);
        expect(opened, 'a');
        expect(selected, 'a');
      } else {
        expect(find.text(Copy.captureNoPhotosHeadline), findsOneWidget);
      }
      expect(added, 0);
    });
  }
  group('Capture field sources and corrections', () {
    const FieldDef automatic = FieldDef(
      fieldKey: 'business',
      label: 'Business',
      type: FieldType.text,
      inputMode: InputMode.auto,
      requiredness: Requiredness.required,
    );
    Widget sourceForm({
      Map<String, Object?> values = const <String, Object?>{},
      Map<String, String> sources = const <String, String>{},
      Map<String, Object?> preview = const <String, Object?>{},
      List<FieldDef> fields = const <FieldDef>[automatic],
      Future<Result<void>> Function(String, Object?)? write,
    }) => wrap(
      CaptureManualForm(
        key: const ValueKey<String>('source-owner'),
        fields: fields,
        values: values,
        valueSources: sources,
        automaticValues: preview,
        onChanged: write ?? (_, _) async => const Success<void>(null),
      ),
    );
    testWidgets(
      'automatic business source reveals an explicit correction and keeps pending source through filtering',
      (WidgetTester tester) async {
        final List<Object?> writes = <Object?>[];
        await tester.pumpWidget(
          sourceForm(
            values: const <String, Object?>{'business': 'Original'},
            sources: const <String, String>{'business': 'AUTO'},
            write: (_, Object? value) async {
              writes.add(value);
              return const Success<void>(null);
            },
          ),
        );
        expect(find.byType(FieldEditor), findsNothing);
        expect(
          find.widgetWithText(AppListTile, Copy.captureFieldAutomatic),
          findsOneWidget,
        );
        final Finder correct = find.byKey(
          const ValueKey<String>('capture-field-correct-business'),
        );
        expect(correct, meetsTapTarget());
        await tester.tap(correct);
        await tester.pumpAndSettle();
        final FieldEditor editor = tester.widget<FieldEditor>(
          find.byType(FieldEditor),
        );
        expect(editor.value.source, ValueSource.auto);
        expect(writes, isEmpty);
        await tester.enterText(
          find.descendant(
            of: find.byType(FieldEditor),
            matching: find.byType(TextField),
          ),
          'Corrected',
        );
        await tester.pumpAndSettle();
        expect(writes, <Object?>['Corrected']);
        expect(
          tester.widget<FieldEditor>(find.byType(FieldEditor)).value.source,
          ValueSource.manual,
        );
        final Finder search = find.descendant(
          of: find.byType(AppSearchField),
          matching: find.byType(TextField),
        );
        await tester.enterText(search, 'none');
        await tester.pumpAndSettle(AppConstants.interaction.debounce);
        await tester.enterText(search, 'business');
        await tester.pumpAndSettle(AppConstants.interaction.debounce);
        expect(
          tester.widget<FieldEditor>(find.byType(FieldEditor)).value.value,
          'Corrected',
        );
        expect(
          find.widgetWithText(AppListTile, Copy.captureFieldManual),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'an explicit typed null suppresses automatic defaults without losing its source',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          sourceForm(
            values: const <String, Object?>{'business': null},
            sources: const <String, String>{'business': 'TYPED'},
            preview: const <String, Object?>{'business': 'Automatic fallback'},
          ),
        );
        final FieldEditor editor = tester.widget<FieldEditor>(
          find.byType(FieldEditor),
        );
        expect(editor.value.value, isNull);
        expect(editor.value.source, ValueSource.manual);
        expect(find.text('Automatic fallback'), findsNothing);
        expect(
          find.widgetWithText(AppListTile, Copy.captureFieldManual),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'reserved metadata and GPS cannot reveal an editor even with a manual source',
      (WidgetTester tester) async {
        final List<FieldDef> fields = <FieldDef>[
          for (final String key in <String>[
            'device_id',
            'record_uid',
            'record_number',
            'captured_by_name',
            'created_at',
            'updated_at',
            'sync_state',
            'gps_latitude',
          ])
            FieldDef(fieldKey: key, label: key, type: FieldType.text),
          const FieldDef(
            fieldKey: 'computed',
            label: 'Computed',
            type: FieldType.computed,
          ),
        ];
        await tester.pumpWidget(
          wrap(
            SingleChildScrollView(
              child: InlineFieldsSection(
                fields: fields,
                showAll: true,
                values: <String, Object?>{
                  for (final FieldDef field in fields)
                    field.fieldKey: 'Original',
                },
                valueSources: <String, String>{
                  for (final FieldDef field in fields) field.fieldKey: 'TYPED',
                },
                onChanged: (_, _) => fail('Immutable value was editable'),
              ),
            ),
          ),
        );
        expect(find.byType(FieldEditor), findsNothing);
        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget.key.toString().contains('capture-field-correct-'),
          ),
          findsNothing,
        );
      },
    );
    for (final FieldType type in <FieldType>[FieldType.date, FieldType.time]) {
      testWidgets(
        '${type.name} pending acknowledgment uses the field codec and releases the acknowledged value',
        (WidgetTester tester) async {
          final FieldDef field = FieldDef(
            fieldKey: 'business',
            label: 'Business',
            type: type,
            autoFill: type == FieldType.date ? AutoFill.today : AutoFill.time,
            requiredness: Requiredness.required,
          );
          final String initial = type == FieldType.date
              ? '2026-10-09'
              : '09:30:00';
          final DateTime edited = DateTime(2026, 10, 10, 11, 45);
          final String acknowledged = storedTextOf(type, edited);
          await tester.pumpWidget(
            sourceForm(
              fields: <FieldDef>[field],
              preview: <String, Object?>{'business': initial},
            ),
          );
          await tester.tap(
            find.byKey(
              const ValueKey<String>('capture-field-correct-business'),
            ),
          );
          await tester.pumpAndSettle();
          tester
              .widget<FieldEditor>(find.byType(FieldEditor))
              .onChanged(FieldValue(fieldKey: 'business', value: edited));
          await tester.pumpAndSettle();
          await tester.pumpWidget(
            sourceForm(
              fields: <FieldDef>[field],
              values: <String, Object?>{'business': acknowledged},
              sources: const <String, String>{'business': 'TYPED'},
            ),
          );
          await tester.pumpAndSettle();
          final String later = type == FieldType.date
              ? '2026-10-11'
              : '12:15:00';
          await tester.pumpWidget(
            sourceForm(
              fields: <FieldDef>[field],
              values: <String, Object?>{'business': later},
              sources: const <String, String>{'business': 'TYPED'},
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.widget<FieldEditor>(find.byType(FieldEditor)).value.value,
            editorValueOf(type, later),
          );
        },
      );
    }
    testWidgets(
      'disposing the owner drops queued edits before invoking callbacks',
      (WidgetTester tester) async {
        final Completer<Result<void>> first = Completer<Result<void>>();
        final List<Object?> writes = <Object?>[];
        await tester.pumpWidget(
          sourceForm(
            values: const <String, Object?>{'business': 'Old'},
            sources: const <String, String>{'business': 'TYPED'},
            write: (_, Object? value) {
              writes.add(value);
              return first.future;
            },
          ),
        );
        final Finder input = find.descendant(
          of: find.byType(FieldEditor),
          matching: find.byType(TextField),
        );
        await tester.enterText(input, 'First');
        await tester.pump();
        await tester.enterText(input, 'Queued');
        await tester.pump();
        await tester.pumpWidget(wrap(const Text('New owner')));
        first.complete(const Success<void>(null));
        await tester.pumpAndSettle();
        expect(writes, <Object?>['First']);
      },
    );
  });
  group('searchable Manual form', () {
    const List<FieldDef> fields = <FieldDef>[
      FieldDef(
        fieldKey: 'asset_key',
        label: 'Équipement',
        type: FieldType.text,
        requiredness: Requiredness.required,
      ),
      FieldDef(
        fieldKey: 'note_key',
        label: 'Équipement note',
        type: FieldType.text,
      ),
      FieldDef(
        fieldKey: 'hidden_key',
        label: 'Équipement hidden',
        type: FieldType.text,
        hidden: true,
      ),
    ];
    Finder input(String key) => find.descendant(
      of: find.byKey(
        ValueKey<String>('field-$key-${FieldEditorKind.appTextField}'),
      ),
      matching: find.byType(TextField),
    );
    Finder getSearch() => find.descendant(
      of: find.byType(AppSearchField),
      matching: find.byType(TextField),
    );
    Future<void> search(WidgetTester tester, String query) async {
      await tester.ensureVisible(getSearch());
      await tester.enterText(getSearch(), query);
      await tester.pumpAndSettle(AppConstants.interaction.debounce);
    }

    Widget form({
      Future<Result<void>> Function(String, Object?)? write,
      Map<String, Object?> values = const <String, Object?>{},
      Key key = const ValueKey<String>('owner-p1-t1-v1'),
      List<FieldDef> shown = fields,
      TextDirection direction = TextDirection.ltr,
    }) => wrap(
      Directionality(
        textDirection: direction,
        child: CaptureManualForm(
          key: key,
          fields: shown,
          values: values,
          onChanged: write ?? (_, _) async => const Success<void>(null),
        ),
      ),
    );

    testWidgets(
      'folded labels and stable keys reveal optional rows in original order',
      (WidgetTester tester) async {
        await tester.pumpWidget(form());
        expect(input('asset_key'), findsOneWidget);
        expect(input('note_key'), findsNothing);
        await search(tester, '  EQUIPEMENT  ');
        expect(input('asset_key'), findsOneWidget);
        expect(input('note_key'), findsOneWidget);
        expect(input('hidden_key'), findsNothing);
        expect(find.text('Équipement'), findsOneWidget);
        expect(
          tester.getTopLeft(input('asset_key')).dy,
          lessThan(tester.getTopLeft(input('note_key')).dy),
        );
        await search(tester, 'NOTE_KEY');
        expect(input('asset_key'), findsNothing);
        expect(input('note_key'), findsOneWidget);
        await search(tester, 'hidden_key');
        expect(find.text(Copy.fieldsNoMatch), findsOneWidget);
        expect(find.text(Copy.searchNoMatchMessage), findsOneWidget);
        expect(input('hidden_key'), findsNothing);
      },
    );

    testWidgets(
      'RTL search preserves original user labels and stable field keys',
      (WidgetTester tester) async {
        await tester.pumpWidget(form(direction: TextDirection.rtl));
        await search(tester, 'EQUIPEMENT');
        expect(input('asset_key'), findsOneWidget);
        expect(input('note_key'), findsOneWidget);
        expect(find.text('Équipement'), findsOneWidget);
        expect(
          Directionality.of(tester.element(input('note_key'))),
          TextDirection.rtl,
        );
        await tester.enterText(input('note_key'), 'RTL value');
        await tester.pumpAndSettle();
        await search(tester, 'asset_key');
        await search(tester, 'note_key');
        expect(
          tester.widget<TextField>(input('note_key')).controller?.text,
          'RTL value',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Clear restores the prior More state and search is ephemeral', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(form());
      await search(tester, 'note');
      await tester.tap(
        find.byTooltip(Copy.clearField(Copy.captureSearchFields)),
      );
      await tester.pumpAndSettle(AppConstants.interaction.debounce);
      expect(input('note_key'), findsNothing);
      await tester.tap(find.text(Copy.captureMoreFields));
      await tester.pumpAndSettle();
      expect(input('note_key'), findsOneWidget);
      await search(tester, 'asset');
      await tester.tap(
        find.byTooltip(Copy.clearField(Copy.captureSearchFields)),
      );
      await tester.pumpAndSettle(AppConstants.interaction.debounce);
      expect(input('note_key'), findsOneWidget);
      await search(tester, 'note');
      await tester.pumpWidget(
        form(key: const ValueKey<String>('owner-p2-t1-v1')),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(getSearch()).controller?.text, isEmpty);
      expect(input('note_key'), findsNothing);
    });

    testWidgets(
      'rapid edits serialize and retain newest input through delayed durable updates',
      (WidgetTester tester) async {
        final List<Completer<Result<void>>> completions =
            <Completer<Result<void>>>[];
        final List<Object?> writes = <Object?>[];
        Future<Result<void>> write(String _, Object? value) {
          writes.add(value);
          final Completer<Result<void>> completion = Completer<Result<void>>();
          completions.add(completion);
          return completion.future;
        }

        await tester.pumpWidget(
          form(
            write: write,
            values: const <String, Object?>{'asset_key': 'old'},
          ),
        );
        await tester.enterText(input('asset_key'), 'first');
        await tester.pump();
        await tester.enterText(input('asset_key'), 'latest');
        await tester.pump();
        expect(writes, <Object?>['first']);
        await search(tester, 'note');
        completions.first.complete(const Success<void>(null));
        await tester.pump();
        expect(writes, <Object?>['first', 'latest']);
        await tester.pumpWidget(
          form(
            write: write,
            values: const <String, Object?>{'asset_key': 'first'},
          ),
        );
        await search(tester, 'asset');
        expect(
          tester.widget<TextField>(input('asset_key')).controller?.text,
          'latest',
        );
        completions.last.complete(const Success<void>(null));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(input('asset_key')).controller?.text,
          'latest',
        );
        await tester.pumpWidget(
          form(
            write: write,
            values: const <String, Object?>{'asset_key': 'latest'},
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(input('asset_key')).controller?.text,
          'latest',
        );
      },
    );

    testWidgets(
      'failure survives filtering with exact retry input and never confirms saved',
      (WidgetTester tester) async {
        bool failing = true;
        final List<Object?> writes = <Object?>[];
        Future<Result<void>> write(String _, Object? value) async {
          writes.add(value);
          return failing
              ? const FailureResult<void>(
                  StorageFailure(message: 'Session write failed'),
                )
              : const Success<void>(null);
        }

        await tester.pumpWidget(form(write: write));
        await tester.enterText(input('asset_key'), 'retained input');
        await tester.pumpAndSettle();
        expect(find.byType(AppErrorState), findsOneWidget);
        await search(tester, 'note');
        await search(tester, 'asset');
        expect(
          tester.widget<TextField>(input('asset_key')).controller?.text,
          'retained input',
        );
        expect(find.byType(AppErrorState), findsOneWidget);
        expect(find.text(Copy.captureSaved), findsNothing);
        failing = false;
        await tester.ensureVisible(find.text(Copy.tryAgain));
        await tester.tap(find.text(Copy.tryAgain));
        await tester.pumpAndSettle();
        expect(writes, <Object?>['retained input', 'retained input']);
        expect(find.byType(AppErrorState), findsNothing);
      },
    );

    testWidgets(
      'large shapes render bounded rows and pinned owner changes discard only ephemeral edits',
      (WidgetTester tester) async {
        final List<FieldDef> large = <FieldDef>[
          for (int index = 0; index < 500; index++)
            FieldDef(
              fieldKey: 'f$index',
              label: 'Field $index',
              type: FieldType.text,
              requiredness: Requiredness.required,
            ),
        ];
        await tester.pumpWidget(form(shown: large));
        expect(find.byType(FieldEditor).evaluate().length, lessThan(30));
        await search(tester, 'f499');
        expect(input('f499'), findsOneWidget);
        expect(find.text('Field 499'), findsOneWidget);
        await tester.pumpWidget(
          form(key: const ValueKey<String>('owner-p1-t1-v2')),
        );
        await tester.pumpAndSettle();
        expect(getSearch(), findsOneWidget);
        expect(tester.widget<TextField>(getSearch()).controller?.text, isEmpty);
        expect(input('asset_key'), findsOneWidget);
        expect(input('f499'), findsNothing);
      },
    );
  });

  testWidgets('recording pauses when the app is interrupted', (
    WidgetTester tester,
  ) async {
    final AudioRecorderService recorder = AudioRecorderService.fake(
      tick: const Duration(seconds: 1),
    );
    await tester.pumpWidget(
      wrap(
        AudioRecorder(
          recorder: recorder,
          relativePath: 'audio/interrupted.wav',
        ),
      ),
    );

    await recorder.start('audio/interrupted.wav');
    await tester.pump();
    expect(find.text(Copy.capturePauseAudio), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.scheduleForcedFrame();
    await tester.pump();
    expect(find.text(Copy.audioRecorderStatus('paused')), findsOneWidget);
    expect(find.text(Copy.captureStopAudio), findsOneWidget);
    expect(find.text(Copy.captureStopAudio), findsOneWidget);

    await recorder.stop();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  group('capture layout', () {
    Future<void> pumpReady(
      WidgetTester tester, {
      required Size size,
      double textScale = 1,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final FakePhotoRepository photos = FakePhotoRepository();
      addTearDown(photos.dispose);
      final FakeProjectRepository projects = FakeProjectRepository();
      addTearDown(projects.dispose);
      final FakeTemplateRepository templates = FakeTemplateRepository();
      addTearDown(templates.dispose);
      await projects.create(aProject(id: 'p1', name: 'Alpha'));
      await templates.save(
        aTemplate(id: 't1', name: 'Assets', projectId: 'p1'),
      );
      await tester.pumpWidget(
        wrap(
          const CaptureScreen(projectId: 'p1'),
          overrides: <Override>[
            photoRepositoryProvider.overrideWith((Ref _) => photos),
            projectRepositoryProvider.overrideWith((Ref _) => projects),
            templateRepositoryProvider.overrideWith((Ref _) => templates),
            capturePersistenceProvider.overrideWith(
              (Ref ref) => CapturePersistenceImpl(
                photos: photos,
                store: TextStore.memory(),
              ),
            ),
            photoPickerProvider.overrideWith(
              (Ref _) => const PhotoPicker.fake(canTakePhoto: true),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    final Finder projectField = find.byKey(
      const ValueKey<String>('capture-project-field'),
    );
    final Finder templateField = find.byKey(
      const ValueKey<String>('capture-template-field'),
    );
    final Finder saveRaw = find.widgetWithText(AppButton, Copy.captureSaveRaw);
    final Finder saveAndProcess = find.byType(AppPrimaryAction);

    const List<({String name, Size size, bool paired})> layouts =
        <({String name, Size size, bool paired})>[
          (name: 'compact portrait', size: Size(360, 740), paired: true),
          (name: 'compact landscape', size: Size(560, 360), paired: true),
          (name: 'medium portrait', size: Size(800, 1200), paired: true),
          (name: 'medium landscape', size: Size(1000, 700), paired: true),
          (name: 'expanded portrait', size: Size(1024, 1366), paired: true),
          (name: 'expanded landscape', size: Size(1366, 1024), paired: true),
        ];

    for (final ({String name, Size size, bool paired}) layout in layouts) {
      testWidgets('in ${layout.name} the selects '
          '${layout.paired ? 'share a row' : 'stack in order'} and the saves '
          'share one level row', (WidgetTester tester) async {
        await pumpReady(tester, size: layout.size);

        final Rect project = tester.getRect(projectField);
        final Rect template = tester.getRect(templateField);
        final Rect raw = tester.getRect(saveRaw);
        final Rect primary = tester.getRect(saveAndProcess);
        if (layout.paired) {
          expect(project.top, template.top);
          expect(project.right, lessThan(template.left));
          expect(project.height, greaterThanOrEqualTo(48));
          expect(template.height, greaterThanOrEqualTo(48));
        } else {
          expect(project.bottom, lessThan(template.top));
          expect(project.left, template.left);
        }
        // One row at every width, the two the same size, the primary at the
        // end (FBK0000158, task 076 D4).
        expect(raw.top, primary.top);
        expect(raw.right, lessThan(primary.left));
        expect(raw.width, closeTo(primary.width, 0.5));
        expect(raw.height, primary.height);
        expect(projectField, meetsTapTarget());
        expect(templateField, meetsTapTarget());
        expect(saveRaw, meetsTapTarget());
        expect(saveAndProcess, meetsTapTarget());
        expect(_addPhotoIcon, meetsTapTarget());
        expect(tester.takeException(), isNull);
      });

      testWidgets('in ${layout.name} nothing overflows at 200 percent text', (
        WidgetTester tester,
      ) async {
        await pumpReady(tester, size: layout.size, textScale: 2);

        expect(tester.takeException(), isNull);
        expect(saveRaw, meetsTapTarget());
        expect(saveAndProcess, meetsTapTarget());
        expect(projectField, meetsTapTarget());
      });
    }

    testWidgets('the empty tray is passive and the composer icon adds', (
      WidgetTester tester,
    ) async {
      await pumpReady(tester, size: const Size(360, 740));

      expect(find.text(Copy.captureNoPhotosHeadline), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, Copy.captureAddPhoto),
        findsNothing,
      );
      expect(find.byTooltip(Copy.captureAddPhoto), findsOneWidget);
      expect(_addPhotoIcon, hasSemanticLabel(Copy.captureAddPhoto));

      await tester.tap(_addPhotoIcon);
      await tester.pumpAndSettle();
      expect(find.text(Copy.captureAddSheetTitle), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, Copy.captureChoosePhoto),
        findsOneWidget,
      );
    });
  });

  testWidgets('inline_fields empty required more validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        InlineFieldsSection(
          fields: const <FieldDef>[],
          values: const <String, Object?>{},
          onChanged: (_, _) {},
        ),
      ),
    );
    expect(find.byKey(const Key('inline-empty')), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        InlineFieldsSection(
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial',
              type: FieldType.text,
              requiredness: Requiredness.required,
            ),
            FieldDef(fieldKey: 'note', label: 'Note', type: FieldType.longText),
          ],
          values: const <String, Object?>{},
          validationErrors: const <String, String>{'serial': 'bad'},
          onChanged: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Serial'), findsOneWidget);
    expect(find.text('bad'), findsOneWidget);
    expect(find.text(Copy.captureMoreFields), findsOneWidget);
    await tester.tap(find.text(Copy.captureMoreFields));
    await tester.pumpAndSettle();
    expect(find.text('Note'), findsOneWidget);
  });

  testWidgets('camera_permission_gate shows the camera once granted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const CameraPermissionGate(child: Text('preview')),
        overrides: <Override>[_camera(PermissionState.granted)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('preview'), findsOneWidget);
    expect(find.text(Copy.captureCameraReason), findsNothing);
  });

  testWidgets('camera_permission_gate explains a denied camera and opens it '
      'on Allow', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        const CameraPermissionGate(child: Text('preview')),
        overrides: <Override>[_camera(PermissionState.denied)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(Copy.captureCameraReason), findsOneWidget);
    expect(find.text(Copy.captureOpenCameraSettings), findsNothing);
    expect(find.text('preview'), findsNothing);

    await tester.tap(find.text(Copy.captureAllowCamera));
    await tester.pumpAndSettle();

    expect(find.text('preview'), findsOneWidget);
  });

  testWidgets('camera_permission_gate offers settings after a permanent '
      'refusal', (WidgetTester tester) async {
    final List<AppPermission> settings = <AppPermission>[];
    await tester.pumpWidget(
      wrap(
        const CameraPermissionGate(child: Text('preview')),
        overrides: <Override>[
          _camera(PermissionState.permanentlyDenied, onOpenSettings: settings),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(Copy.captureCameraReason), findsOneWidget);
    expect(find.text(Copy.captureAllowCamera), findsNothing);

    await tester.tap(find.text(Copy.captureOpenCameraSettings));
    await tester.pumpAndSettle();

    expect(settings, <AppPermission>[AppPermission.camera]);
    expect(find.text('preview'), findsNothing);
  });

  testWidgets('camera_view shows starting, running and failed, and a '
      'pause-resume cycle', (WidgetTester tester) async {
    final CameraService camera = CameraService.fake();
    await tester.pumpWidget(wrap(CameraView(camera: camera)));
    await tester.pumpAndSettle();
    expect(find.byKey(CameraView.previewKey), findsOneWidget);

    await camera.pause();
    await tester.pump();
    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.byKey(CameraView.previewKey), findsNothing);

    await camera.resume();
    await tester.pump();
    expect(find.byKey(CameraView.previewKey), findsOneWidget);

    await tester.pumpWidget(
      wrap(const CameraView(camera: CameraService.unavailable())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(Copy.photoNoCamera), findsOneWidget);
  });

  testWidgets('camera_controls cycle flash, focus, clamp zoom and keep the '
      'grid', (WidgetTester tester) async {
    final CameraService camera = CameraService.fake(maxZoom: 2);
    final SettingsStore settings = SettingsStore.fake();
    Widget camerasScreen() => wrap(
      Column(
        children: <Widget>[
          Expanded(child: CameraView(camera: camera)),
          CameraControls(camera: camera),
        ],
      ),
      overrides: <Override>[
        projectSettingsStoreProvider.overrideWithValue(settings),
      ],
    );
    await tester.pumpWidget(camerasScreen());
    await tester.pumpAndSettle();

    for (final String next in <String>[
      Copy.captureFlashAuto,
      Copy.captureFlashOn,
      Copy.captureFlashOff,
    ]) {
      await tester.tap(
        find.byTooltip(
          <String>[
            Copy.captureFlashOff,
            Copy.captureFlashAuto,
            Copy.captureFlashOn,
          ].firstWhere(
            (String label) => find.byTooltip(label).evaluate().isNotEmpty,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip(next), findsOneWidget);
    }
    expect(camera.flashMode, CameraFlashMode.off);

    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.tap(find.byKey(CameraView.previewKey));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(Copy.captureFocus), findsOneWidget);
    semantics.dispose();

    for (int press = 0; press < 3; press++) {
      final AppIconButton zoomIn = _icon(tester, Copy.captureZoomIn);
      if (zoomIn.onPressed != null) {
        await tester.tap(find.byTooltip(Copy.captureZoomIn));
        await tester.pumpAndSettle();
      }
    }
    expect(camera.zoom, 2);
    expect(_icon(tester, Copy.captureZoomIn).onPressed, isNull);
    for (int press = 0; press < 3; press++) {
      final AppIconButton zoomOut = _icon(tester, Copy.captureZoomOut);
      if (zoomOut.onPressed != null) {
        await tester.tap(find.byTooltip(Copy.captureZoomOut));
        await tester.pumpAndSettle();
      }
    }
    expect(camera.zoom, 1);
    expect(_icon(tester, Copy.captureZoomOut).onPressed, isNull);

    await tester.tap(find.byTooltip(Copy.captureGrid));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(camerasScreen());
    await tester.pumpAndSettle();
    expect(_icon(tester, Copy.captureGrid).selected, isTrue);

    for (final String label in <String>[
      Copy.captureFlashOff,
      Copy.captureGrid,
      Copy.captureZoomOut,
      Copy.captureZoomIn,
      Copy.captureDocumentMode,
    ]) {
      final Finder control = find.ancestor(
        of: find.byTooltip(label),
        matching: find.byType(AppIconButton),
      );
      expect(control, meetsTapTarget(), reason: label);
      expect(control, hasSemanticLabel(label), reason: label);
    }
  });

  testWidgets('document_mode says what it found and offers the corrected '
      'copy only when a page was found', (WidgetTester tester) async {
    final List<String> chosen = <String>[];
    for (final (DocumentBoundary boundary, String message)
        in <(DocumentBoundary, String)>[
          (DocumentBoundary.detected, Copy.capturePageBoundaryFound),
          (DocumentBoundary.notDetected, Copy.captureNoPageBoundary),
          (DocumentBoundary.correctionFailed, Copy.captureCorrectionFailed),
        ]) {
      await tester.pumpWidget(
        wrap(
          DocumentMode(
            boundary: boundary,
            onUseCorrected: () => chosen.add('corrected'),
            onKeepOriginal: () => chosen.add('original'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
      final bool found = boundary == DocumentBoundary.detected;
      expect(
        find.text(Copy.captureUseCorrected),
        found ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(Copy.captureKeepPhoto),
        found ? findsOneWidget : findsNothing,
      );
    }

    await tester.pumpWidget(
      wrap(
        DocumentMode(
          boundary: DocumentBoundary.detected,
          onUseCorrected: () => chosen.add('corrected'),
          onKeepOriginal: () => chosen.add('original'),
        ),
      ),
    );
    await tester.tap(find.text(Copy.captureUseCorrected));
    await tester.tap(find.text(Copy.captureKeepPhoto));
    expect(chosen, <String>['corrected', 'original']);
  });

  testWidgets('gallery and document picker validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        GalleryPicker(
          picker: PhotoPicker.fake(
            photos: <Uint8List>[
              Uint8List.fromList(<int>[1, 2, 3]),
            ],
          ),
          onImported: (_) {},
        ),
      ),
    );
    await tester.tap(find.text(Copy.captureImportGallery));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      wrap(
        DocumentPicker(
          pickBytes: () async =>
              (bytes: Uint8List.fromList(<int>[1, 2, 3]), filename: 'x.txt'),
          onImported: (_, _) {},
        ),
      ),
    );
    await tester.tap(find.text(Copy.captureImportDocument));
    await tester.pumpAndSettle();
  });

  testWidgets('photo tray reorder type multi', (WidgetTester tester) async {
    final List<PhotoDraft> photos = <PhotoDraft>[
      draft('a', type: 'front'),
      draft('b', type: 'serial', order: 1),
    ];
    await tester.pumpWidget(wrap(PhotoTray(photos: photos, onAdd: () {})));
    // The tray draws no type badge: the select control has that corner (D6).
    expect(find.text(Copy.photoFront), findsNothing);
    expect(_selectTarget, findsNWidgets(2));
    await tester.pumpWidget(
      wrap(PhotoReorder(photos: photos, onReorder: (_) {})),
    );
    expect(find.text('front'), findsOneWidget);
    await tester.pumpWidget(
      wrap(PhotoTypeSheet(lastUsed: 'serial', onSelected: (_) {})),
    );
    expect(find.text(Copy.photoSerial), findsOneWidget);
    await tester.pumpWidget(
      wrap(
        PhotoMultiSelect(
          selectedIds: const <String>{'a'},
          allIds: const <String>['a', 'b'],
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text(Copy.captureSelectedCount(1)), findsOneWidget);
    await tester.tap(find.text(Copy.captureSelectAll));
    await tester.pump();
  });

  testWidgets('viewer crop captions voice and barcode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PhotoViewerScreen(
          photos: ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[
            draft('a'),
            draft('b'),
          ]),
          missingIds: const <String>{'b'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewerScreen), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        PhotoCropScreen(
          photo: draft('a'),
          onCropped: (PhotoDraft _, Uint8List? _) {},
          onRevert: (_) {},
        ),
      ),
    );
    await tester.tap(find.widgetWithText(AppButton, Copy.photoCrop));
    await tester.pump();
    await tester.tap(find.text('Revert'));
    await tester.pump();

    await tester.pumpWidget(
      wrap(RecordCaptionField(value: '', onChanged: (String _) async => true)),
    );
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.pump();

    await tester.pumpWidget(
      wrap(
        MicPermissionGate(
          permissions: PermissionsService.fake(
            states: <AppPermission, PermissionState>{
              AppPermission.microphone: PermissionState.denied,
            },
          ),
          child: const Text('typing'),
        ),
      ),
    );
    expect(find.text('typing'), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        VoiceInputButton(
          stt: const SttService.unavailable(),
          languageTag: 'en',
          onFinal: (_) {},
        ),
      ),
    );
    expect(find.byType(VoiceInputButton), findsOneWidget);

    final AudioRecorderService recorder = AudioRecorderService.fake(
      tick: const Duration(seconds: 1),
    );
    await tester.pumpWidget(
      wrap(AudioRecorder(recorder: recorder, relativePath: 'documents/a.wav')),
    );
    expect(find.text(Copy.audioRecorderStatus('idle')), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await recorder.start('documents/a.wav');
    await tester.pump();
    expect(find.text(Copy.audioRecorderStatus('recording')), findsOneWidget);
    expect(find.text(Copy.captureStopAudio), findsOneWidget);
    // The status is a live region: as the clock ticks it must stay the same
    // text, or a screen reader would read it out every second.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(Copy.audioRecorderStatus('recording')), findsOneWidget);
    await recorder.stop();
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pumpWidget(
      wrap(
        BarcodeScannerScreen(
          scanner: FakeBarcodeScannerService(
            hits: const <BarcodeHit>[
              BarcodeHit(rawValue: '123', format: 'code128'),
            ],
          ),
          onConfirmed: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('123'), findsOneWidget);

    await tester.pumpWidget(
      wrap(const BarcodeContinuousMode(scans: <String>['1', '2'])),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.barcodeScanCount(2)), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text(Copy.barcodeCountPosition(2)), findsOneWidget);
  });

  testWidgets('a thumbnail tap opens the photo and the other controls do not', (
    WidgetTester tester,
  ) async {
    PhotoDraft? tapped;
    PhotoDraft? removed;
    final List<String> toggled = <String>[];
    await tester.pumpWidget(
      wrap(
        PhotoTray(
          photos: <PhotoDraft>[draft('a'), draft('b', order: 1)],
          onAdd: () {},
          onTap: (PhotoDraft photo) => tapped = photo,
          onRemove: (PhotoDraft photo) => removed = photo,
          onLongPress: (PhotoDraft photo) => toggled.add(photo.id),
        ),
      ),
    );
    expect(find.text(Copy.capturePhotosSection), findsNothing);
    expect(find.text('Caption'), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('photo-thumb-a')));
    expect(tapped?.id, 'a');
    await tester.tap(find.byTooltip(Copy.captureRemovePhoto).first);
    expect(removed?.id, 'a');
    await tester.tap(_selectTarget.last);
    await tester.longPress(find.byKey(const ValueKey<String>('photo-thumb-a')));
    expect(toggled, <String>['b', 'a']);
    expect(tapped?.id, 'a');
  });

  for (final int turns in <int>[0, 1]) {
    testWidgets('with $turns quarter turns the select and remove controls '
        'are 48dp, apart and flush in the corners', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PhotoTray(
            photos: <PhotoDraft>[
              draft('a').copyWith(rotationDegrees: turns * 90),
            ],
            onAdd: () {},
            onLongPress: (_) {},
            onRemove: (_) {},
            selectedIds: const <String>{'a'},
          ),
        ),
      );
      final Rect select = tester.getRect(_selectTarget);
      final Rect remove = tester.getRect(_removeTarget);
      final Rect thumb = tester.getRect(
        find.byKey(const ValueKey<String>('photo-thumb-a')),
      );
      expect(select.size, const Size.square(48));
      expect(remove.size, const Size.square(48));
      expect(select.overlaps(remove), isFalse);
      expect(
        tester
            .getRect(find.byKey(const ValueKey<String>('photo-corner-select')))
            .topLeft,
        thumb.topLeft,
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey<String>('photo-corner-remove')))
            .topRight,
        thumb.topRight,
      );
      expect(
        tester.getSemantics(_selectTarget),
        matchesSemantics(
          label: Copy.photoSelect,
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(_removeTarget),
        matchesSemantics(
          label: Copy.captureRemovePhoto,
          isButton: true,
          hasTapAction: true,
        ),
      );
    });
  }

  testWidgets('a tray without remove draws no remove control', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PhotoTray(
          photos: <PhotoDraft>[draft('a')],
          onAdd: () {},
          onLongPress: (_) {},
        ),
      ),
    );
    expect(_selectTarget, findsOneWidget);
    expect(_removeTarget, findsNothing);
  });

  testWidgets('the preview shows a caption to edit and delete with undo', (
    WidgetTester tester,
  ) async {
    final Map<String, String> writes = <String, String>{};
    await tester.pumpWidget(
      wrap(
        PhotoViewerScreen(
          photos: ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[draft('a')]),
          captions: const <String, String>{'a': 'Boiler room'},
          onCaptionChanged: (PhotoDraft photo, String text) async {
            writes[photo.id] = text;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Boiler room'), findsOneWidget);
    expect(find.byTooltip(Copy.photoCrop), findsOneWidget);
    expect(find.byTooltip(Copy.photoRotate), findsOneWidget);

    await tester.tap(find.text(Copy.photoCaptionEdit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Pump room');
    await tester.tap(find.text(Copy.save));
    await tester.pumpAndSettle();
    expect(writes['a'], 'Pump room');
    expect(find.text('Pump room'), findsOneWidget);

    await tester.tap(find.text(Copy.photoCaptionDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.photoCaptionDelete).last);
    await tester.pumpAndSettle();
    expect(writes['a'], '');
    expect(find.text(Copy.photoNoCaption), findsOneWidget);
    expect(find.text(Copy.photoCaptionDelete), findsNothing);

    await tester.tap(find.text(Copy.undo));
    await tester.pumpAndSettle();
    expect(writes['a'], 'Pump room');
    expect(find.text('Pump room'), findsOneWidget);
  });

  testWidgets('a new version shows in the preview at the same position', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<List<PhotoDraft>> photos =
        ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[draft('a'), draft('b')]);
    addTearDown(photos.dispose);
    final Uint8List bytes = _onePixelPng();
    await tester.pumpWidget(
      wrap(
        PhotoViewerScreen(
          photos: photos,
          initialIndex: 1,
          captions: const <String, String>{'b': 'Pump room'},
          images: <String, Uint8List>{'a': bytes, 'b': bytes, 'b2': bytes},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('photo-viewer-image-b')),
      findsOneWidget,
    );

    photos.value = <PhotoDraft>[
      draft('a'),
      draft('b2').copyWith(derivedFrom: 'b'),
    ];
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('photo-viewer-image-b2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('photo-viewer-image-b')),
      findsNothing,
    );
    expect(find.text('Pump room'), findsOneWidget);
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
      ]) {
    testWidgets('in ${layout.name} the preview caption stays on screen', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = layout.size;
      tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        wrap(
          PhotoViewerScreen(
            photos: ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[draft('a')]),
            captions: const <String, String>{'a': 'Boiler room'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final Rect edit = tester.getRect(find.text(Copy.photoCaptionEdit));
      expect(edit.bottom, lessThanOrEqualTo(layout.size.height));
    });
  }
}

/// A valid 1×1 PNG.
Uint8List _onePixelPng() {
  final img.Image image = img.Image(width: 1, height: 1);
  return Uint8List.fromList(img.encodePng(image));
}

final Finder _selectTarget = find.byKey(
  const ValueKey<String>('photo-corner-select-target'),
);

final Finder _removeTarget = find.byKey(
  const ValueKey<String>('photo-corner-remove-target'),
);

/// The empty tray's add-photo icon, which is its add action (FBK0000004).
final Finder _addPhotoIcon = find.byKey(
  const ValueKey<String>('capture-composer-add-photo'),
);

/// The camera permission in [state]; a settings request lands in
/// [onOpenSettings].
Override _camera(PermissionState state, {List<AppPermission>? onOpenSettings}) {
  return permissionsServiceProvider.overrideWithValue(
    PermissionsService.fake(
      states: <AppPermission, PermissionState>{AppPermission.camera: state},
      onOpenSettings: onOpenSettings?.add,
    ),
  );
}
