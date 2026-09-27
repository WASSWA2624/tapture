import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';

import 'support/harness.dart';

void main() {
  test('each caption scope lands on exactly its photos', () async {
    final TestApp app = await bootTestApp();
    addTearDown(app.dispose);
    const List<String> photos = <String>['p1', 'p2', 'p3', 'p4'];
    final Map<String, String> captions = <String, String>{};

    void apply(Set<String> selected, String text) {
      final List<String> targets = CaptionApply.targets(
        visibleIds: photos,
        selectedIds: selected,
      );
      final List<CaptionWrite> writes = CaptionApply.apply(
        photoIds: targets,
        text: text,
        mode: CaptionApplyMode.replace,
        existing: captions,
      );
      for (final CaptionWrite write in writes) {
        captions[write.photoId] = write.text;
      }
    }

    apply(<String>{'p1'}, 'one');
    expect(captions['p1'], 'one');
    expect(captions.containsKey('p2'), isFalse);

    apply(<String>{'p2', 'p3', 'p4'}, 'three');
    expect(captions['p1'], 'one');
    expect(captions['p2'], 'three');
    expect(captions['p3'], 'three');
    expect(captions['p4'], 'three');

    apply(<String>{}, 'all');
    expect(captions.values.toSet(), <String>{'all'});

    apply(<String>{'p2'}, 'edited');
    expect(captions['p2'], 'edited');
    expect(captions['p1'], 'all');
    expect(captions['p3'], 'all');
    expect(app.outboundCallCount, 0);
  });
}
