import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/theme_controller.dart';

import 'golden_harness.dart';

void main() {
  testWidgets(
    'a one-pixel change fails the suite and names the widget and mode',
    (WidgetTester tester) async {
      await expectGolden(
        tester,
        const _PixelProbe(shifted: false),
        'pixel_probe',
        modes: const <AppThemeMode>[AppThemeMode.light],
      );
      if (autoUpdateGoldenFiles) {
        return;
      }
      final GoldenFileComparator previous = goldenFileComparator;
      final _SpyGoldenComparator spy = _SpyGoldenComparator(previous);
      goldenFileComparator = spy;
      addTearDown(() {
        goldenFileComparator = previous;
      });
      await expectGolden(
        tester,
        const _PixelProbe(shifted: true),
        'pixel_probe',
        modes: const <AppThemeMode>[AppThemeMode.light],
      );
      expect(spy.last, isNotNull, reason: 'pixel_probe in light');
      expect(
        spy.last!.passed,
        isFalse,
        reason:
            'pixel_probe in light: a one-pixel change must fail the suite '
            '(FE-TEST-02)',
      );
    },
  );
}

class _SpyGoldenComparator implements GoldenFileComparator {
  _SpyGoldenComparator(this._inner);

  final GoldenFileComparator _inner;
  ComparisonResult? last;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    last = await GoldenFileComparator.compareLists(
      imageBytes,
      File(
        'test/design_system/goldens/${golden.pathSegments.last}',
      ).readAsBytesSync(),
    );
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) {
    return _inner.update(golden, imageBytes);
  }

  @override
  Uri getTestUri(Uri key, int? version) {
    return _inner.getTestUri(key, version);
  }
}

class _PixelProbe extends StatelessWidget {
  const _PixelProbe({required this.shifted});

  final bool shifted;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PixelPainter(shifted: shifted),
      child: const SizedBox.expand(),
    );
  }
}

class _PixelPainter extends CustomPainter {
  const _PixelPainter({required this.shifted});

  final bool shifted;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF007700),
    );
    if (shifted) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1, 1),
        Paint()..color = const Color(0xFFFF0000),
      );
    }
  }

  @override
  bool shouldRepaint(_PixelPainter oldDelegate) {
    return oldDelegate.shifted != shifted;
  }
}
