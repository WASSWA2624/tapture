import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/import/domain/import_duplicates.dart';

void main() {
  test('each choice and apply-to-all', () {
    expect(ImportDuplicates.apply(matched: false), ImportMatch.create);
    expect(
      ImportDuplicates.apply(
        matched: true,
        choice: ImportDuplicateChoice.keepExisting,
      ),
      ImportMatch.keep,
    );
    expect(
      ImportDuplicates.apply(
        matched: true,
        choice: ImportDuplicateChoice.replace,
      ),
      ImportMatch.replace,
    );
    expect(
      ImportDuplicates.apply(
        matched: true,
        choice: ImportDuplicateChoice.merge,
      ),
      ImportMatch.merge,
    );
    expect(ImportDuplicates.apply(matched: true), ImportMatch.ask);
    expect(
      ImportDuplicates.apply(
        matched: true,
        applyToAll: ImportDuplicateChoice.keepExisting,
      ),
      ImportMatch.keep,
    );
  });
}
