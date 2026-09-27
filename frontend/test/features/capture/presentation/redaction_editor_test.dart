import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/features/capture/presentation/redaction_editor.dart';

void main() {
  test(
    'the sent copy differs inside the mark and matches outside it',
    () async {
      final img.Image source = img.Image(width: 4, height: 4);
      img.fill(source, color: img.ColorRgb8(10, 20, 30));
      source.setPixel(1, 1, img.ColorRgb8(200, 10, 10));
      final Uint8List original = img.encodePng(source);
      final Uint8List sent = await RedactionEditor.burn(
        original,
        const <RedactionMark>[(x: 1, y: 1, width: 1, height: 1)],
      );
      expect(
        img.decodeImage(original)!.getPixel(0, 0),
        img.decodeImage(sent)!.getPixel(0, 0),
      );
      expect(
        img.decodeImage(sent)!.getPixel(1, 1),
        isNot(img.decodeImage(original)!.getPixel(1, 1)),
      );
    },
  );

  testWidgets('a tap adds a mark, and empty and failure states show', (
    WidgetTester tester,
  ) async {
    List<RedactionMark> marks = const <RedactionMark>[];
    await tester.pumpWidget(
      MaterialApp(
        home: RedactionEditor(
          marks: marks,
          onChanged: (List<RedactionMark> next) => marks = next,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('redaction-surface')));
    await tester.pump();
    expect(marks, isNotEmpty);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RedactionEditor(
          marks: <RedactionMark>[],
          onChanged: _ignore,
          empty: true,
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey<String>('redaction-surface')),
      findsNothing,
    );
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RedactionEditor(
          marks: <RedactionMark>[],
          onChanged: _ignore,
          failure: 'The photo could not be shown.',
        ),
      ),
    );
    expect(find.text('The photo could not be shown.'), findsOneWidget);
  });
}

void _ignore(List<RedactionMark> _) {}
