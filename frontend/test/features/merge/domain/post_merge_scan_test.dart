import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/post_merge_scan.dart';

void main() {
  test('only an incoming record is compared with a local one', () {
    const List<ScanRecord> local = <ScanRecord>[
      (id: 'l1', identity: 'pump'),
      (id: 'l2', identity: 'valve'),
    ];
    const List<ScanRecord> incoming = <ScanRecord>[
      (id: 'i1', identity: 'pump'),
    ];
    final List<ScanPair> pairs = PostMergeScan.scan(
      local: local,
      incoming: incoming,
      score: (ScanRecord here, ScanRecord arrived) =>
          here.identity == arrived.identity ? 1 : 0,
    );
    expect(pairs, hasLength(1));
    expect(pairs.single.localId, 'l1');
    expect(pairs.single.incomingId, 'i1');
    expect(
      PostMergeScan.scan(
        local: local,
        incoming: const <ScanRecord>[],
        score: (ScanRecord _, ScanRecord _) => 1,
      ),
      isEmpty,
    );
  });
}
