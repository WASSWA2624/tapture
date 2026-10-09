import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/app.dart';

import 'screen_fonts.dart';

/// Changes only test direction around the production application's builder.
final class RtlTaptureApp extends TaptureApp {
  const RtlTaptureApp({super.receiveIncomingBundles = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      withRtlDirectionality(super.build(context, ref) as MaterialApp);
}

/// Uses licensed SDK UI metrics without changing the production app's routes,
/// roles, sizes, weights, colours, controls or root builder composition.
final class ScreenTaptureApp extends TaptureApp {
  const ScreenTaptureApp({
    this.direction,
    super.receiveIncomingBundles = false,
    super.key,
  });

  final TextDirection? direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      withTestApplicationConfiguration(
        super.build(context, ref) as MaterialApp,
        direction: direction,
        screenFonts: true,
      );
}

/// Changes only direction around the existing root builder's returned subtree.
MaterialApp withRtlDirectionality(MaterialApp app) =>
    withTestApplicationConfiguration(app, direction: TextDirection.rtl);

/// Forwards every current router constructor property, with explicit optional
/// test-only direction and font-family substitutions.
MaterialApp withTestApplicationConfiguration(
  MaterialApp app, {
  TextDirection? direction,
  bool screenFonts = false,
}) => MaterialApp.router(
  key: app.key,
  scaffoldMessengerKey: app.scaffoldMessengerKey,
  routeInformationProvider: app.routeInformationProvider,
  routeInformationParser: app.routeInformationParser,
  routerDelegate: app.routerDelegate,
  routerConfig: app.routerConfig,
  backButtonDispatcher: app.backButtonDispatcher,
  builder: direction == null
      ? app.builder
      : (BuildContext context, Widget? child) => Directionality(
          textDirection: direction,
          child:
              app.builder?.call(context, child) ??
              child ??
              const SizedBox.shrink(),
        ),
  title: app.title,
  onGenerateTitle: app.onGenerateTitle,
  onNavigationNotification: app.onNavigationNotification,
  color: app.color,
  theme: _theme(app.theme, screenFonts),
  darkTheme: _theme(app.darkTheme, screenFonts),
  highContrastTheme: _theme(app.highContrastTheme, screenFonts),
  highContrastDarkTheme: _theme(app.highContrastDarkTheme, screenFonts),
  themeMode: app.themeMode,
  themeAnimationDuration: app.themeAnimationDuration,
  themeAnimationCurve: app.themeAnimationCurve,
  themeAnimationStyle: app.themeAnimationStyle,
  locale: app.locale,
  localizationsDelegates: app.localizationsDelegates,
  localeListResolutionCallback: app.localeListResolutionCallback,
  localeResolutionCallback: app.localeResolutionCallback,
  supportedLocales: app.supportedLocales,
  debugShowMaterialGrid: app.debugShowMaterialGrid,
  showPerformanceOverlay: app.showPerformanceOverlay,
  checkerboardRasterCacheImages: app.checkerboardRasterCacheImages,
  checkerboardOffscreenLayers: app.checkerboardOffscreenLayers,
  showSemanticsDebugger: app.showSemanticsDebugger,
  debugShowCheckedModeBanner: app.debugShowCheckedModeBanner,
  shortcuts: app.shortcuts,
  actions: app.actions,
  restorationScopeId: app.restorationScopeId,
  scrollBehavior: app.scrollBehavior,
);

ThemeData? _theme(ThemeData? theme, bool screenFonts) =>
    screenFonts && theme != null ? ScreenFonts.theme(theme) : theme;
