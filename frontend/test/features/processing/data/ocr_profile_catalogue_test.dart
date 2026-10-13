import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/domain/ocr_field_mapping.dart';
import 'package:tapture/features/processing/domain/ocr_mapping_outcome.dart';
import 'package:tapture/features/processing/domain/ocr_mapping_profile.dart';
import 'package:tapture/features/processing/domain/ocr_parameter_block.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/templates.dart' hide TemplateRow;

void main() {
  test(
    'every shipped template has its own versioned typed OCR mapping profile',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 13));
      final Map<String, Future<String>> assets = <String, Future<String>>{};
      final ShippedTemplateLoader loader = ShippedTemplateLoader(
        templates: TemplateRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: 'profile-test',
          ids: UuidV7Service.sequence(clock),
        ),
        readAsset: (String path) =>
            assets.putIfAbsent(path, () => File(path).readAsString()),
      );
      final List<ShippedTemplateEntry> entries = (await loader.entries())
          .getOrThrow();
      expect(entries, isNotEmpty);
      final Set<String> checked = <String>{};
      for (final ShippedTemplateEntry entry in entries) {
        final TemplateDef template = (await loader.template(
          entry.templateKey,
        )).getOrThrow();
        final OcrMappingProfile profile = OcrMappingProfile.fromTemplate(
          template,
        );
        expect(profile.templateKey, entry.templateKey);
        expect(profile.templateVersion, template.version);
        expect(
          profile.fields.map((FieldDef f) => f.fieldKey).toSet(),
          template.fields
              .where(FieldInputPolicy.canExtract)
              .map((FieldDef f) => f.fieldKey)
              .toSet(),
        );
        for (final FieldDef field in profile.fields) {
          final OcrMappingOutcome outcome = OcrFieldMapping.extract(
            text: '${field.fieldKey.replaceAll('_', ' ')}: photographed value',
            blocks: const <OcrParameterBlock>[],
            profile: profile,
          );
          expect(
            outcome.labelledKeys,
            contains(field.fieldKey),
            reason:
                '${entry.templateKey}:${field.fieldKey} has no parameter mapper',
          );
        }
        checked.add(profile.templateKey);
      }
      expect(checked.length, entries.length);
    },
  );
}
