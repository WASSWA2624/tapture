import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/features/templates/data/template_migration_repository_impl.dart';
import 'package:tapture/features/templates/domain/template_migration_repository.dart';

import '../../../support/factories.dart';

void main() {
  test(
    'the production migration port watches the shared database and filters template ownership',
    () async {
      final AppDatabase db = await seededDatabase(records: 2);
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final TemplateMigrationRepository repository = container.read(
        templateMigrationRepositoryProvider,
      );
      final Template template = await db.select(db.templates).getSingle();
      expect(await repository.watch(template.id).first, hasLength(2));
      expect(await repository.watch('not-this-template').first, isEmpty);
    },
  );
}
