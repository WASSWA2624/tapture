import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Named haptic patterns. Features never call [HapticFeedback] themselves
/// (FE-STR-11).
abstract interface class Haptics {
  /// Platform-backed haptics. [enabled] and reduced-motion are read once
  /// (FE-A11Y-08).
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
  return WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;
}

void _playPlatform(String pattern) {
  unawaited(_impact(pattern));
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
