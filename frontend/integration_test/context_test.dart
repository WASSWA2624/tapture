import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/context/domain/context_override.dart';
import 'package:tapture/features/context/domain/context_state.dart';
import 'package:tapture/features/records/domain/record_entry.dart';
import 'package:tapture/features/records/domain/record_repository.dart';

import '../test/support/matchers.dart';
import 'support/capture_rig.dart';
import 'support/harness.dart';

void main() {
  test(
    'a context override stays on its record when the project changes',
    () async {
      final TestApp app = await bootTestApp();
      addTearDown(app.dispose);
      const List<ContextLevel> levels = <ContextLevel>[
        ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
        ContextLevel(fieldKey: 'site', order: 1, label: 'Site'),
      ];
      valueOf(await app.context.saveHierarchy('project-1', levels));
      valueOf(
        await app.context.setLevelValue(
          projectId: 'project-1',
          fieldKey: 'district',
          value: 'North',
          clearBelow: false,
        ),
      );
      valueOf(
        await app.context.setLevelValue(
          projectId: 'project-1',
          fieldKey: 'site',
          value: 'Yard',
          clearBelow: false,
        ),
      );
      final ContextState project = valueOf(await app.context.load('project-1'));
      final List<RecordEntry> records = <RecordEntry>[];
      for (var index = 0; index < 5; index++) {
        final RecordEntry entry = await app.capture(
          fields: <String, String>{'serial': 'C-$index'},
        );
        valueOf(
          await app.contextRecords.applyToRecord(
            recordId: entry.id,
            state: project,
          ),
        );
        records.add(valueOf(await app.records.byId(entry.id))!);
      }
      valueOf(
        await app.contextRecords.overrideField(
          recordId: records.first.id,
          fieldKey: 'district',
          newValue: 'South',
        ),
      );
      valueOf(
        await app.context.setLevelValue(
          projectId: 'project-1',
          fieldKey: 'district',
          value: 'East',
        ),
      );
      for (final RecordEntry entry in records.skip(1)) {
        valueOf(
          await app.records.editValues(entry.id, <RecordValueEdit>[
            (fieldKey: 'district', value: 'East'),
          ]),
        );
      }
      final RecordEntry overridden = valueOf(
        await app.records.byId(records.first.id),
      )!;
      expect(
        ContextOverride.isOverridden(
          rawValue: overridden.valueOf('district')?.raw,
          refinedValue: overridden.valueOf('district')?.refined,
        ),
        isTrue,
      );
      expect(overridden.valueOf('district')?.raw, 'North');
      for (final RecordEntry entry in records.skip(1)) {
        final RecordEntry current = valueOf(await app.records.byId(entry.id))!;
        expect(current.valueOf('district')?.display, 'East');
        expect(current.valueOf('district')?.refined, isNot('South'));
      }
      expect(app.outboundCallCount, 0);
    },
  );

  test('a photo captured into a three-level context is filed under '
      'photos/Kampala/Kasubi-HC-IV/Theatre', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    final CaptureRig capture = await CaptureRig.open(app);
    valueOf(
      await app.context
          .saveHierarchy(CaptureRig.projectId, const <ContextLevel>[
            ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
            ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
            ContextLevel(fieldKey: 'department', order: 2, label: 'Department'),
          ]),
    );
    for (final (String level, String value) in <(String, String)>[
      ('district', 'Kampala'),
      ('facility', 'Kasubi HC IV'),
      ('department', 'Theatre'),
    ]) {
      valueOf(
        await app.context.setLevelValue(
          projectId: CaptureRig.projectId,
          fieldKey: level,
          value: value,
          clearBelow: false,
        ),
      );
    }
    final ContextState place = valueOf(
      await app.context.load(CaptureRig.projectId),
    );
    // The shutter fires before the page has applied the context.
    final PhotoDraft shot = await capture.shoot();
    valueOf(await capture.controller.setTemplate(CaptureRig.templateId));
    valueOf(await capture.controller.setContext(place.values));

    final String recordId = valueOf(
      await capture.controller.saveRaw(
        capture.container.read(captureRecordWriterProvider)!.persist,
      ),
    );

    final Photo row = await (app.db.select(
      app.db.photos,
    )..where(($PhotosTable table) => table.id.equals(shot.id))).getSingle();
    expect(row.recordId, recordId);
    expect(
      row.relativePath,
      'photos/Kampala/Kasubi-HC-IV/Theatre/${shot.id}.jpg',
    );
    expect(capture.file(row.relativePath).existsSync(), isTrue);
    expect(capture.file(shot.relativePath).existsSync(), isFalse);
    expect(app.outboundCallCount, 0);
  });
}
