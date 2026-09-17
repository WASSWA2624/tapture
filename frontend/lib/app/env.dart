import 'package:flutter/foundation.dart';

/// The compile-time flavour, and a test hook that overrides it.
///
/// Flavour-dependent values are provided at the provider scope, not by
/// branching on [flavor] in feature code (FE-STATE-03, FE-STR-04).
abstract final class Env {
  /// The flavour this binary was compiled with, or [debugFlavor] in tests.
  static Flavor get flavor => debugFlavor ?? _compiledFlavor;

  /// Whether this binary is the development flavour.
  static bool get isDev => flavor == Flavor.dev;

  /// Test-only stand-in for the compile-time flavour.
  @visibleForTesting
  static Flavor? debugFlavor;

  static Flavor get _compiledFlavor {
    const String defined = String.fromEnvironment('FLAVOR');
    const String fromGradle = String.fromEnvironment('FLUTTER_APP_FLAVOR');
    const String name = defined != '' ? defined : fromGradle;
    return switch (name) {
      'dev' => Flavor.dev,
      _ => Flavor.prod,
    };
  }
}

/// Which install this binary was compiled as.
enum Flavor {
  /// A development install that sits alongside production.
  dev,

  /// The production install.
  prod,
}
