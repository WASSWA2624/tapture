import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/processing/data/proposal_preview.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

import '../../../support/processing_fixture.dart';

void main() {
  test(
    'mapped photo parameters preserve raw text and present canonical unapproved values',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      final ProcessingJob job = await fixture.job();
      await fixture.addField('frequency', type: 'decimal', unit: 'Hz');
      await fixture.addField('capacity', type: 'decimal', unit: 'L');
      await fixture.addField('working', type: 'boolean');
      await fixture.addField(
        'condition',
        type: 'choice',
        options: '[{"label":"Good","code":"GOOD","aliases":["OK"]}]',
      );
      await fixture.addField('inspection_date', type: 'date');
      const String text =
          'Frequency: 50 Hz\nCapacity: 1000 mL\nWorking: Yes\nCondition: OK\nInspection date: 13/10/2026';
      final worker = fixture.worker(ocr: CountingOcr(text));
      await worker.perform(JobStage.prepare, job);
      await worker.perform(JobStage.onDevice, job);
      final List<PreviewedValue> preview = (await worker.preview.forRecord(
        fixture.record.id,
      )).getOrThrow();
      expect(
        <String, String>{
          for (final value in preview) value.fieldKey: value.value,
        },
        <String, String>{
          'frequency': '50',
          'capacity': '1',
          'working': 'true',
          'condition': 'GOOD',
          'inspection_date': '2026-10-13',
        },
      );
      await worker.perform(JobStage.validate, job);
      final Map<String, RecordField> fields = <String, RecordField>{
        for (final RecordField field
            in await fixture.db.select(fixture.db.recordFields).get())
          field.fieldKey: field,
      };
      expect(fields['frequency']!.valueRaw, '50 Hz');
      expect(fields['frequency']!.valueRefined, '50');
      expect(fields['capacity']!.valueRaw, '1000 mL');
      expect(fields['capacity']!.valueRefined, '1');
      expect(fields['working']!.valueRaw, 'Yes');
      expect(fields['working']!.valueRefined, 'true');
      expect(fields['condition']!.valueRaw, 'OK');
      expect(fields['condition']!.valueRefined, 'GOOD');
      expect(fields['inspection_date']!.valueRaw, '13/10/2026');
      expect(fields['inspection_date']!.valueRefined, '2026-10-13');
      expect(
        fields.values.every(
          (field) => !field.verified && field.valueFinal == null,
        ),
        isTrue,
      );
      expect(
        (await fixture.db.select(fixture.db.ocrCacheEntries).getSingle())
            .recognisedText,
        text,
      );
    },
  );
}
