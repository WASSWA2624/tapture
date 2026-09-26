import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/template_assets.dart';
import 'package:tapture/core/db/app_database.dart' hide TemplateRow;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/templates/data/shipped_template_loader.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/domain/shipped_template_entry.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

void main() {
  late AppDatabase db;
  late TemplateRepositoryImpl repo;
  late ShippedTemplateLoader loader;

  final DateTime t0 = DateTime.utc(2026, 9, 20, 8);
  final FixedClock clock = FixedClock(t0);

  setUp(() {
    db = AppDatabase.memory();
    repo = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
    loader = ShippedTemplateLoader(
      templates: repo,
      readAsset: (String path) => File(path).readAsString(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'copying writes a project-owned version 1 and leaves the asset',
    () async {
      final TemplateDef first = _ok(
        await loader.copyToProject(
          templateKey: 'uni_general_observation',
          projectId: 'project-1',
          name: 'Site observations',
        ),
      );
      expect(first.id, isNotEmpty);
      expect(first.projectId, 'project-1');
      expect(first.version, 1);
      expect(first.source, 'shipped');
      expect(first.name, 'Site observations');
      expect(first.templateKey, 'uni_general_observation');

      final TemplateDef shipped = _ok(
        await loader.template('uni_general_observation'),
      );
      expect(shipped.projectId, isNull);
      expect(shipped.name, startsWith('templates.'));
      expect(shipped.fields.first.label, startsWith('templates.'));
    },
  );

  test('editing one copy leaves the library and a second copy alone', () async {
    final TemplateDef first = _ok(
      await loader.copyToProject(
        templateKey: 'uni_general_observation',
        projectId: 'project-1',
        name: 'First',
      ),
    );
    final TemplateDef second = _ok(
      await loader.copyToProject(
        templateKey: 'uni_general_observation',
        projectId: 'project-1',
        name: 'Second',
      ),
    );
    expect(first.id, isNot(second.id));

    final TemplateDef edited = _ok(
      await repo.save(
        first.copyWith(
          fields: <FieldDef>[
            ...first.fields,
            const FieldDef(
              fieldKey: 'extra_note',
              label: 'Extra note',
              type: FieldType.text,
            ),
          ],
        ),
      ),
    );
    expect(
      edited.fields.map((FieldDef field) => field.fieldKey),
      contains('extra_note'),
    );

    final TemplateDef reloaded = _ok(await repo.byId(second.id))!;
    expect(reloaded.name, 'Second');
    expect(
      reloaded.fields.map((FieldDef field) => field.fieldKey),
      isNot(contains('extra_note')),
    );
    expect(reloaded.fields.length, first.fields.length);

    final TemplateDef shipped = _ok(
      await loader.template('uni_general_observation'),
    );
    expect(
      shipped.fields.map((FieldDef field) => field.fieldKey),
      isNot(contains('extra_note')),
    );
  });

  test('a broken template fails validation and writes nothing', () async {
    final ShippedTemplateLoader broken = ShippedTemplateLoader(
      templates: repo,
      readAsset: (String path) async {
        final String text = await File(path).readAsString();
        return path.endsWith('_uni_universal_capture_and_records.json')
            ? text.replaceAll('"schema_version": 1', '"schema_version": 2')
            : text;
      },
    );
    final Result<TemplateDef> result = await broken.template(
      'uni_general_observation',
    );
    expect(result, isA<FailureResult<TemplateDef>>());
    final Result<TemplateDef> copied = await broken.copyToProject(
      templateKey: 'uni_general_observation',
      projectId: 'project-1',
      name: 'Broken',
    );
    expect(copied, isA<FailureResult<TemplateDef>>());
    expect(await repo.watchByProject('project-1').first, isEmpty);
  });

  group('the library', () {
    test('entries list every template in catalogue order', () async {
      final List<ShippedTemplateEntry> catalogue = _ok(await loader.entries());
      final Map<String, Object?> index = _json(TemplateAssets.catalogueIndex);

      expect(index['template_count'], 2349);
      expect(catalogue, hasLength(2349));
      expect(
        catalogue
            .map((ShippedTemplateEntry entry) => entry.templateKey)
            .toSet(),
        hasLength(catalogue.length),
      );
      expect(
        catalogue
            .map((ShippedTemplateEntry entry) => entry.category.code)
            .toSet(),
        hasLength(72),
      );
      expect(
        catalogue
            .map((ShippedTemplateEntry entry) => entry.category.supergroupCode)
            .toSet(),
        hasLength(17),
      );
      for (final ShippedTemplateEntry entry in catalogue) {
        expect(entry.title, isNotEmpty, reason: entry.templateKey);
        expect(entry.code, matches(RegExp(r'^[A-Z]{2,4}-\d{3}$')));
        expect(entry.kind, entry.recordType.kind);
        expect(entry.fieldKeys, isNotEmpty, reason: entry.templateKey);
        expect(entry.fieldCount, greaterThan(55), reason: entry.templateKey);
        expect(<String>{
          'internal',
          'confidential',
          'restricted',
        }, contains(entry.privacy));
        expect(<String>{'p0', 'p1', 'p2'}, contains(entry.rollout));
      }
      final ShippedTemplateEntry observation = catalogue.first;
      expect(observation.templateKey, 'uni_general_observation');
      expect(observation.code, 'UNI-001');
      expect(observation.title, 'General observation');
      expect(observation.recordType.code, 'OBS');
      expect(observation.recordType.capture, isNotEmpty);
      expect(observation.recordType.review, isNotEmpty);
    });

    test('a catalogue template resolves every group it inherits', () async {
      final TemplateDef observation = _ok(
        await loader.template('uni_general_observation'),
      );
      final List<String> keys = <String>[
        for (final FieldDef field in observation.fields) field.fieldKey,
      ];
      final ShippedTemplateEntry entry = _ok(await loader.entries()).firstWhere(
        (ShippedTemplateEntry row) =>
            row.templateKey == 'uni_general_observation',
      );

      expect(observation.source, 'shipped');
      expect(observation.version, 1);
      expect(observation.projectId, isNull);
      expect(observation.kind, 'observation');
      expect(keys, hasLength(entry.fieldCount));
      expect(keys.toSet(), hasLength(keys.length));
      expect(
        keys,
        containsAllInOrder(<String>[
          'record_uid',
          'site_code',
          'caption_raw',
          'reviewed_date',
          'organization_ref',
          'observation_subject',
          'observed_at',
          'observation_category',
          'observed_details',
        ]),
      );
      expect(observation.identityFieldKeys, <String>[
        'observation_subject',
        'observed_at',
      ]);
      final FieldDef subject = _field(observation, 'observation_subject');
      expect(subject.identity, isTrue);
      expect(subject.requiredness, Requiredness.required);
      expect(subject.group, 'observation');
      final FieldDef observedAt = _field(observation, 'observed_at');
      expect(observedAt.type, FieldType.dateTime);
      expect(observedAt.autoFill, AutoFill.now);
      final FieldDef context = _field(observation, 'organization_ref');
      expect(context.stickable, isTrue);
      expect(context.group, 'context');
      expect(context.requiredness, Requiredness.recommended);
      final FieldDef status = _field(observation, 'verification_status');
      expect(status.type, FieldType.choice);
      expect(status.options, hasLength(4));
      final FieldDef details = _field(observation, 'observed_details');
      expect(details.type, FieldType.longText);
      expect(details.refine, isTrue);
      expect(details.group, 'specific_details');
      expect(details.requiredness, Requiredness.recommended);
    });

    test('money in a catalogue template comes with its currency', () async {
      final TemplateDef invoice = _ok(
        await loader.template('fin_invoice_ocr_intake'),
      );
      final FieldDef total = _field(invoice, 'total_amount');
      expect(total.type, FieldType.currency);
      expect(total.inputMode, InputMode.manualOnly);
      expect(
        invoice.fields.map((FieldDef field) => field.fieldKey),
        contains('total_currency'),
      );
      expect(invoice.identityFieldKeys, <String>['transaction_reference']);
    });

    test('one template of every category resolves', () async {
      final Map<String, ShippedTemplateEntry> firsts =
          <String, ShippedTemplateEntry>{};
      for (final ShippedTemplateEntry entry in _ok(await loader.entries())) {
        firsts.putIfAbsent(entry.category.code, () => entry);
      }
      expect(firsts, hasLength(72));
      for (final ShippedTemplateEntry entry in firsts.values) {
        final TemplateDef template = _ok(
          await loader.template(entry.templateKey),
        );
        expect(
          template.fields,
          hasLength(entry.fieldCount),
          reason: entry.templateKey,
        );
        expect(
          template.fields.where((FieldDef field) => field.identity),
          isNotEmpty,
          reason: entry.templateKey,
        );
      }
    });

    test('copying a catalogue template writes an editable copy', () async {
      final TemplateDef copy = _ok(
        await loader.copyToProject(
          templateKey: 'uni_general_observation',
          projectId: 'project-1',
          name: 'General observation',
        ),
      );
      expect(copy.id, isNotEmpty);
      expect(copy.projectId, 'project-1');
      expect(copy.version, 1);
      expect(copy.name, 'General observation');
      expect(copy.kind, 'observation');
      expect(
        copy.fields.map((FieldDef field) => field.label),
        isNot(contains(startsWith('templates.'))),
      );
      expect(
        _field(copy, 'observation_category').label,
        'Observation category',
      );
      expect(
        _field(copy, 'verification_status').options,
        contains(
          predicate<Object>(
            (Object option) => option is Map && option['label'] == 'Verified',
          ),
        ),
      );
      expect(await repo.watchByProject('project-1').first, hasLength(1));
    });

    test('an unknown key is a validation failure and writes nothing', () async {
      final Result<TemplateDef> missing = await loader.template('no_such_key');
      expect(missing, isA<FailureResult<TemplateDef>>());
      expect(
        (missing as FailureResult<TemplateDef>).failure,
        isA<ValidationFailure>(),
      );
      final Result<TemplateDef> copied = await loader.copyToProject(
        templateKey: 'no_such_key',
        projectId: 'project-1',
        name: 'Nothing',
      );
      expect(copied, isA<FailureResult<TemplateDef>>());
      expect(await repo.watchByProject('project-1').first, isEmpty);
    });

    test('a catalogue naming an unknown group fails to list', () async {
      final ShippedTemplateLoader broken = ShippedTemplateLoader(
        templates: repo,
        readAsset: (String path) async {
          final String text = await File(path).readAsString();
          if (path == TemplateAssets.catalogueGroups) {
            return '{}';
          }
          return text;
        },
      );
      final Result<List<ShippedTemplateEntry>> result = await broken.entries();
      expect(result, isA<FailureResult<List<ShippedTemplateEntry>>>());
    });
  });

  test('copying without a name fails and writes nothing', () async {
    final Result<TemplateDef> result = await loader.copyToProject(
      templateKey: 'uni_general_observation',
      projectId: 'project-1',
      name: '   ',
    );
    expect(result, isA<FailureResult<TemplateDef>>());
    expect(await repo.watchByProject('project-1').first, isEmpty);
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

FieldDef _field(TemplateDef template, String key) {
  return template.fields.firstWhere((FieldDef field) => field.fieldKey == key);
}

Map<String, Object?> _json(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
}
