import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/typography.dart' show AppText;

import 'screen_font_fetch_stub.dart'
    if (dart.library.js_interop) 'screen_font_fetch_web.dart';

/// Production UI font metrics for layout tests, independent of Ahem goldens.
/// The SDK already supplies these licensed fonts; no network asset is loaded.
abstract final class ScreenFonts {
  static Future<void>? _loaded;
  static Future<void>? _appLoaded;

  /// Loads the default Android UI faces once per widget-test isolate.
  static Future<void> load() => _loaded ??= _load();

  /// Loads real metrics for an isolated application-shell fixture. Each
  /// platform's Material typography requests its native families, which the
  /// test engine cannot load. These aliases preserve its production roles.
  /// Other test isolates retain their normal Ahem goldens because [load]
  /// never registers these aliases.
  static Future<void> loadForApp() => _appLoaded ??= _loadForApp();

  static Future<void> _loadForApp() async {
    await load();
    if (kIsWeb) return;
    final Uri sdk = await _sdk();
    final Set<String> families = <String>{'Ahem', ...AppText.fontFallback};
    for (final TargetPlatform platform in TargetPlatform.values) {
      final TextTheme theme = Typography.material2021(platform: platform).black;
      for (final TextStyle? style in <TextStyle?>[
        theme.displayLarge,
        theme.displayMedium,
        theme.displaySmall,
        theme.headlineLarge,
        theme.headlineMedium,
        theme.headlineSmall,
        theme.titleLarge,
        theme.titleMedium,
        theme.titleSmall,
        theme.bodyLarge,
        theme.bodyMedium,
        theme.bodySmall,
        theme.labelLarge,
        theme.labelMedium,
        theme.labelSmall,
      ]) {
        if (style?.fontFamily case final String family) families.add(family);
        families.addAll(style?.fontFamilyFallback ?? const <String>[]);
      }
    }
    for (final String family in families) {
      if (family != 'Roboto') await _loadNativeFaces(sdk, family);
    }
  }

  static Future<void> _load() async {
    if (kIsWeb) {
      await _loadBrowser();
      return;
    }
    final Uri sdk = await _sdk();
    await _loadNativeFaces(sdk, 'Roboto');
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

  static Future<Uri> _sdk() async {
    final File config = File('.dart_tool/package_config.json');
    final Map<String, Object?> contents =
        jsonDecode(await config.readAsString()) as Map<String, Object?>;
    final List<Object?> packages = contents['packages']! as List<Object?>;
    final Map<String, Object?> flutter = packages
        .cast<Map<String, Object?>>()
        .singleWhere((package) => package['name'] == 'flutter');
    return Directory.fromUri(
      config.absolute.uri.resolve(flutter['rootUri']! as String),
    ).uri.resolve('../../');
  }

  static Future<void> _loadNativeFaces(Uri sdk, String family) async {
    final FontLoader loader = FontLoader(family);
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
