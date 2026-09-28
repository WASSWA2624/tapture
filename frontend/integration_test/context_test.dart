import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/context/domain/context_override.dart';
import 'package:tapture/features/context/domain/context_state.dart';
import 'package:tapture/features/records/domain/record_entry.dart';
import 'package:tapture/features/records/domain/record_repository.dart';

import '../test/support/matchers.dart';
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
}
