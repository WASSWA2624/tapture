import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/template_assets.dart';
import 'package:tapture/core/db/app_database.dart' hide TemplateRow;
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/templates/data/shipped_template_loader.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';
import 'package:tapture/features/templates/presentation/template_duplicate_action.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the bundled global library saves and attaches independent editable copies offline',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 8));
      final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'offline',
        ids: UuidV7Service.sequence(clock),
      );
      final Map<String, String> readAssets = <String, String>{};
      final ShippedTemplateLoader loader = ShippedTemplateLoader(
        templates: templates,
        readAsset: (String path) async {
          final String bytes = await rootBundle.loadString(path);
          readAssets[path] = bytes;
          return bytes;
        },
      );
      expect(await db.select(db.projects).get(), isEmpty);
      final TemplateDef original = (await loader.template(
        'uni_general_observation',
      )).getOrThrow();
      expect(original.id, isEmpty);
      final TemplateDef library = (await loader.copyToLibrary(
        templateKey: original.templateKey,
        name: 'Custom observation',
      )).getOrThrow();
      expect((await templates.watchLibrary().first).single.id, library.id);
      final TemplateDef projectCopy = (await templates.save(
        TemplateDuplicateAction.draftFrom(
          library,
        ).copyWith(projectId: 'field-project'),
      )).getOrThrow();
      expect(projectCopy.id, isNot(library.id));
      expect(projectCopy.version, 1);
      final List<TemplateField> fields = await db
          .select(db.templateFields)
          .get();
      final Set<String> sourceIds = fields
          .where((row) => row.templateId == library.id)
          .map((row) => row.id)
          .toSet();
      expect(
        fields
            .where((row) => row.templateId == projectCopy.id)
            .map((row) => row.id)
            .toSet()
            .intersection(sourceIds),
        isEmpty,
      );
      final TemplateDef edited = (await templates.save(
        library.copyWith(
          name: 'Revised custom observation',
          fields: <FieldDef>[
            library.fields.first.copyWith(label: 'Custom label'),
          ],
        ),
      )).getOrThrow();
      expect(edited.version, library.version + 1);
      (await templates.delete(
        library.id,
        reason: 'Delete the library source',
      )).getOrThrow();
      expect(await templates.watchLibrary().first, isEmpty);
      expect((await templates.byId(projectCopy.id)).getOrThrow(), projectCopy);
      (await templates.restore(library.id)).getOrThrow();
      expect((await templates.watchLibrary().first).single, edited);
      expect(
        (await loader.template(original.templateKey)).getOrThrow(),
        original,
      );
      expect(readAssets.keys, contains(TemplateAssets.catalogueIndex));
      for (final MapEntry<String, String> entry in readAssets.entries) {
        expect(await rootBundle.loadString(entry.key), entry.value);
      }
      expect(await db.select(db.projects).get(), isEmpty);
    },
  );
}
