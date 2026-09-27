import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/merge_reference.dart';

void main() {
  test(
    'a new key inserts, an identical key is quiet, a difference conflicts',
    () {
      expect(
        MergeReference.resolve(
          localExists: false,
          local: const <String, String>{},
          incoming: const <String, String>{'name': 'Ada'},
        ),
        ReferenceOutcome.insert,
      );
      expect(
        MergeReference.resolve(
          localExists: true,
          local: const <String, String>{'name': 'Ada'},
          incoming: const <String, String>{'name': 'Ada'},
        ),
        ReferenceOutcome.identical,
      );
      expect(
        MergeReference.resolve(
          localExists: true,
          local: const <String, String>{'name': 'Ada'},
          incoming: const <String, String>{'name': 'Grace'},
        ),
        ReferenceOutcome.conflict,
      );
    },
  );
}
