import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/context/domain/context_movement_prompt.dart';

/// A location source that counts how often it is asked for a fix.
final class _FakeFixSource {
  _FakeFixSource(this.fix);

  ({double latitude, double longitude})? fix;
  int reads = 0;

  ({double latitude, double longitude})? read() {
    reads += 1;
    return fix;
  }
}

void main() {
  const ({double latitude, double longitude}) origin = (
    latitude: 0,
    longitude: 0,
  );
  const ({double latitude, double longitude}) farAway = (
    latitude: 0.002,
    longitude: 0,
  );
  const ({double latitude, double longitude}) nearby = (
    latitude: 0.0005,
    longitude: 0,
  );
  const double threshold = 100;

  late _FakeFixSource source;

  setUp(() {
    source = _FakeFixSource(farAway);
  });

  ({bool prompt, bool readFix}) evaluate({
    bool enabled = true,
    bool gpsEnabled = true,
    bool locationGranted = true,
    double thresholdMetres = threshold,
    ({double latitude, double longitude})? from = origin,
  }) {
    return ContextMovementPrompt.evaluate(
      enabled: enabled,
      gpsEnabled: gpsEnabled,
      locationGranted: locationGranted,
      thresholdMetres: thresholdMetres,
      readFix: source.read,
      origin: from,
    );
  }

  group('off', () {
    test('never reads a fix and never prompts', () {
      final ({bool prompt, bool readFix}) decision = evaluate(enabled: false);
      expect(decision, (prompt: false, readFix: false));
      expect(source.reads, 0);
    });

    test('with GPS disabled never reads a fix', () {
      final ({bool prompt, bool readFix}) decision = evaluate(
        gpsEnabled: false,
      );
      expect(decision, (prompt: false, readFix: false));
      expect(source.reads, 0);
    });
  });

  group('permission denied', () {
    test('never reads a fix and never prompts', () {
      final ({bool prompt, bool readFix}) decision = evaluate(
        locationGranted: false,
      );
      expect(decision, (prompt: false, readFix: false));
      expect(source.reads, 0);
    });

    test('is not overridden by a distance already known', () {
      expect(
        ContextMovementPrompt.shouldPrompt(
          enabled: true,
          gpsEnabled: true,
          locationGranted: false,
          distanceMetres: threshold * 10,
          thresholdMetres: threshold,
        ),
        isFalse,
      );
    });
  });

  group('fired', () {
    test('a fix past the threshold reads once and asks for confirmation', () {
      final ({bool prompt, bool readFix}) decision = evaluate();
      expect(decision, (prompt: true, readFix: true));
      expect(source.reads, 1);
    });

    test('a fix short of the threshold reads but asks nothing', () {
      source.fix = nearby;
      final ({bool prompt, bool readFix}) decision = evaluate();
      expect(decision, (prompt: false, readFix: true));
      expect(source.reads, 1);
    });

    test('the first fix only sets the origin', () {
      final ({bool prompt, bool readFix}) decision = evaluate(from: null);
      expect(decision, (prompt: false, readFix: true));
      expect(source.reads, 1);
    });

    test('no signal reads but asks nothing', () {
      source.fix = null;
      expect(evaluate(), (prompt: false, readFix: true));
    });

    test('a zero threshold never asks', () {
      expect(evaluate(thresholdMetres: 0), (prompt: false, readFix: true));
    });

    test('the threshold itself is far enough', () {
      bool ask(double metres) {
        return ContextMovementPrompt.shouldPrompt(
          enabled: true,
          gpsEnabled: true,
          locationGranted: true,
          distanceMetres: metres,
          thresholdMetres: threshold,
        );
      }

      expect(ask(threshold), isTrue);
      expect(ask(threshold - 0.01), isFalse);
    });
  });

  group('distance', () {
    test('one degree of latitude is about 111 km', () {
      expect(
        ContextMovementPrompt.metresBetween(origin, (
          latitude: 1,
          longitude: 0,
        )),
        closeTo(111195, 1),
      );
    });

    test('is symmetric and zero for the same point', () {
      expect(
        ContextMovementPrompt.metresBetween(origin, farAway),
        ContextMovementPrompt.metresBetween(farAway, origin),
      );
      expect(ContextMovementPrompt.metresBetween(farAway, farAway), 0);
    });

    test('shrinks with latitude for the same longitude step', () {
      final double atEquator = ContextMovementPrompt.metresBetween(
        (latitude: 0, longitude: 0),
        (latitude: 0, longitude: 0.001),
      );
      final double atSixty = ContextMovementPrompt.metresBetween(
        (latitude: 60, longitude: 0),
        (latitude: 60, longitude: 0.001),
      );
      expect(atSixty, closeTo(atEquator / 2, 1));
    });
  });
}
