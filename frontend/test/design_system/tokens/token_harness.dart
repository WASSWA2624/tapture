import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/color_tokens.dart';

/// The three palettes every token must exist on (FE-THEME-02).
const List<AppColors> tokenModes = <AppColors>[
  AppColors.light,
  AppColors.dark,
  AppColors.outdoor,
];

/// A short name for [colors] used in golden file names.
String tokenModeName(AppColors colors) {
  if (identical(colors, AppColors.dark)) {
    return 'dark';
  }
  if (identical(colors, AppColors.outdoor)) {
    return 'outdoor';
  }
  return 'light';
}

/// Pumps [child] under [colors], with an optional text scale.
Future<void> pumpTokenTree(
  WidgetTester tester, {
  required AppColors colors,
  required Widget child,
  double textScale = 1,
  Size size = const Size(400, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final Brightness brightness = identical(colors, AppColors.dark)
      ? Brightness.dark
      : Brightness.light;
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme: ThemeData(
        brightness: brightness,
        useMaterial3: true,
        extensions: <ThemeExtension<dynamic>>[colors],
      ),
      builder: (BuildContext context, Widget? nested) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(size: size, textScaler: TextScaler.linear(textScale)),
          child: nested!,
        );
      },
      home: Scaffold(backgroundColor: colors.background, body: child),
    ),
  );
}
