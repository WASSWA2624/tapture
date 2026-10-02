import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Named haptic patterns. Features never call [HapticFeedback] themselves
/// (FE-STR-11).
abstract interface class Haptics {
  /// Platform-backed haptics. [enabled] and reduced-motion are read once
  /// (FE-A11Y-08). The platform honours the system haptics setting itself:
  /// with it off, every pattern is silent (FE-A11Y-08).
  factory Haptics({bool enabled = true, bool? reduceMotion}) {
    return _Haptics(
      enabled: enabled,
      reduceMotion: reduceMotion ?? _systemReduceMotion(),
      play: _playPlatform,
    );
  }

  /// A recording stand-in. Tests assert against [played] and never vibrate
  /// the device (FE-TEST-03).
  factory Haptics.fake({
    required List<String> played,
    bool enabled = true,
    bool reduceMotion = false,
  }) {
    return _Haptics(
      enabled: enabled,
      reduceMotion: reduceMotion,
      play: played.add,
    );
  }

  /// Capture shutter. Heavier than [save] so the two can be told apart
  /// without looking (FE-A11Y-09).
  void shutter();

  /// A successful save. Distinct from [shutter].
  void save();

  /// Advisory warning.
  void warning();

  /// A failure the operator should feel.
  void error();

  /// A selection or toggle. Skipped while reduced motion is on.
  void selection();
}

/// Process-wide haptics that capture and save confirm with. Tests override
/// it with [Haptics.fake].
final Provider<Haptics> hapticsProvider = Provider<Haptics>((Ref _) {
  return Haptics();
});

final class _Haptics implements Haptics {
  _Haptics({
    required this.enabled,
    required this.reduceMotion,
    required this.play,
  });

  final bool enabled;
  final bool reduceMotion;
  final void Function(String pattern) play;

  @override
  void shutter() => _emit('shutter');

  @override
  void save() => _emit('save');

  @override
  void warning() => _emit('warning');

  @override
  void error() => _emit('error');

  @override
  void selection() => _emit('selection');

  void _emit(String pattern) {
    if (!enabled) {
      return;
    }
    if (reduceMotion && pattern == 'selection') {
      return;
    }
    play(pattern);
  }
}

bool _systemReduceMotion() {
  return PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
}

/// Plays [pattern]. A device without a vibrator, or no platform at all, is
/// not an error the operator should see.
void _playPlatform(String pattern) {
  _impact(pattern).ignore();
}

Future<void> _impact(String pattern) {
  return switch (pattern) {
    'shutter' => HapticFeedback.heavyImpact(),
    'save' => HapticFeedback.mediumImpact(),
    'warning' => HapticFeedback.lightImpact(),
    'error' => HapticFeedback.vibrate(),
    'selection' => HapticFeedback.selectionClick(),
    _ => Future<void>.value(),
  };
}
