import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';

void main() {
  group('targets', () {
    const List<String> tray = <String>['a', 'b', 'c'];

    test('one photo is its own target', () {
      expect(
        CaptionApply.targets(
          visibleIds: const <String>['a'],
          selectedIds: const <String>{},
        ),
        <String>['a'],
      );
    });

    test('with none selected every visible photo is a target', () {
      expect(
        CaptionApply.targets(visibleIds: tray, selectedIds: const <String>{}),
        tray,
      );
    });

    test('a selection narrows the targets and keeps tray order', () {
      expect(
        CaptionApply.targets(
          visibleIds: tray,
          selectedIds: const <String>{'c', 'a', 'gone'},
        ),
        <String>['a', 'c'],
      );
    });

    test('the targets are a copy, never the tray itself', () {
      final List<String> visible = <String>['a', 'b'];
      final List<String> targets = CaptionApply.targets(
        visibleIds: visible,
        selectedIds: const <String>{},
      );

      targets.add('z');

      expect(visible, <String>['a', 'b']);
    });
  });

  group('sharedText', () {
    const Map<String, String> captions = <String, String>{
      'a': 'Site',
      'b': 'Site',
      'c': 'Pump',
    };

    test('is the caption every target holds', () {
      expect(
        CaptionApply.sharedText(
          ids: const <String>['a', 'b'],
          captions: captions,
        ),
        'Site',
      );
    });

    test('is empty when the targets differ, are absent or are none', () {
      expect(
        CaptionApply.sharedText(
          ids: const <String>['a', 'b', 'c'],
          captions: captions,
        ),
        '',
      );
      expect(
        CaptionApply.sharedText(
          ids: const <String>['a', 'x'],
          captions: captions,
        ),
        '',
      );
      expect(
        CaptionApply.sharedText(ids: const <String>[], captions: captions),
        '',
      );
    });
  });

  group('apply', () {
    test('append adds the new text on a new line after the previous', () {
      final List<CaptionWrite> writes = CaptionApply.apply(
        photoIds: <String>['a'],
        text: 'new',
        mode: CaptionApplyMode.append,
        existing: const <String, String>{'a': 'old'},
      );

      expect(writes.single.text, 'old\nnew');
    });

    test('append onto an empty caption writes just the new text', () {
      final List<CaptionWrite> writes = CaptionApply.apply(
        photoIds: <String>['a', 'b'],
        text: 'new',
        mode: CaptionApplyMode.append,
        existing: const <String, String>{'a': '   '},
      );

      expect(writes[0].text, 'new');
      expect(writes[1].text, 'new');
    });

    test('append with blank text keeps the previous caption as it was', () {
      final List<CaptionWrite> writes = CaptionApply.apply(
        photoIds: <String>['a'],
        text: ' ',
        mode: CaptionApplyMode.append,
        existing: const <String, String>{'a': 'old'},
      );

      expect(writes.single.text, 'old');
    });

    test('append records no previous value because nothing is lost', () {
      final List<CaptionWrite> writes = CaptionApply.apply(
        photoIds: <String>['a'],
        text: 'new',
        mode: CaptionApplyMode.append,
        existing: const <String, String>{'a': 'old'},
      );

      expect(writes.single.previousText, isNull);
    });

    test('replace keeps the previous caption recoverable', () {
      final List<CaptionWrite> writes = CaptionApply.apply(
        photoIds: <String>['a'],
        text: 'x',
        mode: CaptionApplyMode.replace,
        existing: const <String, String>{'a': 'old'},
      );

      expect(writes.single.text, 'x');
      expect(writes.single.previousText, 'old');
    });

    test('replace on a photo with no caption has nothing to recover', () {
      final List<CaptionWrite> writes = CaptionApply.apply(
        photoIds: <String>['a'],
        text: 'x',
        mode: CaptionApplyMode.replace,
        existing: const <String, String>{},
      );

      expect(writes.single.previousText, isNull);
    });

    test('applying to seven photos writes seven independent rows', () {
      final List<String> ids = <String>[for (var i = 1; i <= 7; i++) 'p$i'];
      final Map<String, String> existing = <String, String>{
        for (final String id in ids) id: 'was $id',
      };

      final List<CaptionWrite> writes = CaptionApply.apply(
        photoIds: ids,
        text: 'Boiler room',
        mode: CaptionApplyMode.replace,
        existing: existing,
      );

      expect(writes, hasLength(7));
      expect(writes.map((CaptionWrite w) => w.photoId), ids);
      for (final CaptionWrite write in writes) {
        expect(write.text, 'Boiler room');
        expect(write.previousText, 'was ${write.photoId}');
      }
    });

    test('a row written to one photo later leaves the other six alone', () {
      final List<String> ids = <String>[for (var i = 1; i <= 7; i++) 'p$i'];
      final Map<String, String> captions = <String, String>{
        for (final CaptionWrite write in CaptionApply.apply(
          photoIds: ids,
          text: 'Boiler room',
          mode: CaptionApplyMode.replace,
          existing: const <String, String>{},
        ))
          write.photoId: write.text,
      };

      final List<CaptionWrite> later = CaptionApply.apply(
        photoIds: const <String>['p4'],
        text: 'Pump room',
        mode: CaptionApplyMode.replace,
        existing: captions,
      );
      for (final CaptionWrite write in later) {
        captions[write.photoId] = write.text;
      }

      expect(later.single.previousText, 'Boiler room');
      expect(captions['p4'], 'Pump room');
      for (final String id in ids.where((String id) => id != 'p4')) {
        expect(captions[id], 'Boiler room');
      }
    });

    test('a photo outside the scope gets no row', () {
      final List<CaptionWrite> writes = CaptionApply.apply(
        photoIds: <String>['a'],
        text: 'x',
        mode: CaptionApplyMode.append,
        existing: const <String, String>{'a': 'old', 'b': 'other'},
      );

      expect(writes.map((CaptionWrite w) => w.photoId), <String>['a']);
    });
  });
}
