import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen_font_fetch_stub.dart'
    if (dart.library.js_interop) 'screen_font_fetch_web.dart';

/// Production UI font metrics for layout tests, independent of Ahem goldens.
/// The SDK already supplies these licensed fonts; no network asset is loaded.
abstract final class ScreenFonts {
  static Future<void>? _loaded;

  /// Loads the default Android UI faces once per widget-test isolate.
  static Future<void> load() => _loaded ??= _load();

  static Future<void> _load() async {
    if (kIsWeb) {
      await _loadBrowser();
      return;
    }
    final File config = File('.dart_tool/package_config.json');
    final Map<String, Object?> contents =
        jsonDecode(await config.readAsString()) as Map<String, Object?>;
    final List<Object?> packages = contents['packages']! as List<Object?>;
    final Map<String, Object?> flutter = packages
        .cast<Map<String, Object?>>()
        .singleWhere((package) => package['name'] == 'flutter');
    final Uri sdk = Directory.fromUri(
      config.absolute.uri.resolve(flutter['rootUri']! as String),
    ).uri.resolve('../../');
    final FontLoader loader = FontLoader('Roboto');
    for (final String face in <String>['regular', 'medium', 'bold']) {
      final File file = File.fromUri(
        sdk.resolve('bin/cache/artifacts/material_fonts/roboto-$face.ttf'),
      );
      if (!await file.exists()) {
        throw TestFailure(
          'The SDK production UI font is missing: ${file.path}',
        );
      }
      final Future<ByteData> data = file.readAsBytes().then(
        (Uint8List bytes) => ByteData.sublistView(bytes),
      );
      loader.addFont(data);
    }
    await loader.load();
    final File icons = File.fromUri(
      sdk.resolve(
        'bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      ),
    );
    if (!await icons.exists()) {
      throw TestFailure('The SDK icon font is missing: ${icons.path}');
    }
    final FontLoader iconLoader = FontLoader('MaterialIcons')
      ..addFont(
        icons.readAsBytes().then(
          (Uint8List bytes) => ByteData.sublistView(bytes),
        ),
      );
    await iconLoader.load();
  }

  static Future<void> _loadBrowser() async {
    final Uri fonts = Uri.base.resolve('/task143-fonts/');
    final FontLoader loader = FontLoader('Roboto');
    for (final String face in <String>['regular', 'medium', 'bold']) {
      loader.addFont(fetchScreenFont(fonts.resolve('roboto-$face.ttf')));
    }
    await loader.load();
    await (FontLoader(
          'MaterialIcons',
        )..addFont(fetchScreenFont(fonts.resolve('materialicons-regular.otf'))))
        .load();
    useScreenFontMetrics();
  }

  /// Uses Roboto for every inherited UI role, preserving production sizes,
  /// weights, line heights, colours and the requested system text scale.
  static ThemeData theme(ThemeData theme) => theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: 'Roboto',
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _buttonStyle(theme.filledButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _buttonStyle(theme.outlinedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _buttonStyle(theme.textButtonTheme.style),
    ),
  );

  static ButtonStyle _buttonStyle(ButtonStyle? style) =>
      (style ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) =>
              (style?.textStyle?.resolve(states) ?? const TextStyle()).copyWith(
                fontFamily: 'Roboto',
              ),
        ),
      );
}
