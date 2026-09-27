import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/merge_fields.dart';

void main() {
  test(
    'one-sided changes apply, identical values do not, differences escalate',
    () {
      expect(
        MergeFields.compare(
          mine: 'a',
          theirs: 'a',
          mineChanged: true,
          theirsChanged: true,
        ),
        FieldMerge.identical,
      );
      expect(
        MergeFields.compare(
          mine: 'a',
          theirs: 'b',
          mineChanged: true,
          theirsChanged: false,
        ),
        FieldMerge.applyMine,
      );
      expect(
        MergeFields.compare(
          mine: 'a',
          theirs: 'b',
          mineChanged: true,
          theirsChanged: true,
        ),
        FieldMerge.escalate,
      );
    },
  );
}
