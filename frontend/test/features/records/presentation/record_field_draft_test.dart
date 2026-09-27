import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/presentation/record_field_draft.dart';

void main() {
  late ProviderContainer container;
  late List<Map<String, String>> seen;

  setUp(() {
    container = ProviderContainer();
    seen = <Map<String, String>>[];
    container.listen(
      recordFieldDraftProvider('r1'),
      (Map<String, String>? _, Map<String, String> next) => seen.add(next),
    );
  });

  tearDown(() => container.dispose());

  RecordFieldDraft draft([String id = 'r1']) {
    return container.read(recordFieldDraftProvider(id).notifier);
  }

  Map<String, String> typed([String id = 'r1']) {
    return container.read(recordFieldDraftProvider(id));
  }

  test('it starts with nothing typed', () {
    expect(typed(), isEmpty);
  });

  test('set keeps the latest text per field', () {
    draft()
      ..set('asset_tag', 'A-1')
      ..set('asset_tag', 'A-18')
      ..set('notes', 'Leaking');

    expect(typed(), <String, String>{'asset_tag': 'A-18', 'notes': 'Leaking'});
    expect(() => typed()['x'] = 'y', throwsUnsupportedError);
  });

  test('the same text again notifies nobody', () {
    draft().set('asset_tag', 'A-18');
    final int before = seen.length;

    draft().set('asset_tag', 'A-18');

    expect(seen.length, before);
  });

  test('forget drops only the saved fields', () {
    draft()
      ..set('asset_tag', 'A-18')
      ..set('notes', 'Leaking');
    final int before = seen.length;

    draft().forget(<String>['other']);
    expect(seen.length, before);
    draft().forget(<String>['asset_tag']);

    expect(typed(), <String, String>{'notes': 'Leaking'});
  });

  test('clear drops everything typed', () {
    draft().set('asset_tag', 'A-18');

    draft().clear();
    final int before = seen.length;
    draft().clear();

    expect(typed(), isEmpty);
    expect(seen.length, before);
  });

  test('each record keeps its own draft', () {
    draft().set('asset_tag', 'A-18');

    expect(typed('r2'), isEmpty);
  });

  test('closing the last reader forgets what was typed', () async {
    final ProviderContainer scope = ProviderContainer();
    addTearDown(scope.dispose);
    final ProviderSubscription<Map<String, String>> page = scope.listen(
      recordFieldDraftProvider('r1'),
      (_, _) {},
    );
    scope.read(recordFieldDraftProvider('r1').notifier).set('asset_tag', 'A');

    page.close();
    await scope.pump();

    expect(scope.read(recordFieldDraftProvider('r1')), isEmpty);
  });
}
