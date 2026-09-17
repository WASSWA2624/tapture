import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'dimensions.dart';
import 'typography.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [ThemeData] built by [buildTheme].
typedef AppTheme = ThemeData;

/// Material 3 [ThemeData] for [brightness], optionally the high-contrast
/// outdoor variant (FE-THEME-02, FE-THEME-07).
///
/// Stock buttons, fields, chips, dialogs, sheets and app bars pick up Tapture
/// styling here, so a screen that redecorates one is a defect.
ThemeData buildTheme({required Brightness brightness, bool outdoor = false}) {
  final AppColors colors = _palette(brightness: brightness, outdoor: outdoor);
  final ColorScheme scheme = _scheme(brightness, colors);
  final TextTheme textTheme = _textTheme(colors);
  final BorderSide outline = _outline(colors, outdoor);
  const RoundedRectangleBorder controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(Radii.md)),
  );
  const ButtonStyle controlStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll<Size>(
      Size(Sizes.minTapTarget, Sizes.minTapTarget),
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(horizontal: Space.x3, vertical: Space.x1),
    ),
    shape: WidgetStatePropertyAll<OutlinedBorder>(controlShape),
    elevation: WidgetStatePropertyAll<double>(0),
    shadowColor: WidgetStatePropertyAll<Color>(Color(0x00000000)),
    textStyle: WidgetStatePropertyAll<TextStyle>(AppText.label),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.background,
    applyElevationOverlayColor: false,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: <ThemeExtension<dynamic>>[colors],
    appBarTheme: AppBarThemeData(
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: Sizes.minTapTarget + Space.x2,
      backgroundColor: brightness == Brightness.dark
          ? colors.surface
          : colors.primary,
      foregroundColor: brightness == Brightness.dark
          ? colors.onSurface
          : colors.onPrimary,
      surfaceTintColor: brightness == Brightness.dark
          ? colors.surface
          : colors.primary,
      shadowColor: const Color(0x00000000),
      centerTitle: false,
      titleSpacing: Space.x3,
      actionsPadding: const EdgeInsetsDirectional.only(end: Space.x1),
      titleTextStyle: AppText.title.copyWith(
        color: brightness == Brightness.dark
            ? colors.onSurface
            : colors.onPrimary,
      ),
      iconTheme: IconThemeData(
        color: brightness == Brightness.dark
            ? colors.onSurface
            : colors.onPrimary,
        size: Space.x6,
      ),
      actionsIconTheme: IconThemeData(
        color: brightness == Brightness.dark
            ? colors.onSurface
            : colors.onPrimary,
        size: Space.x6,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: controlStyle.copyWith(
        backgroundColor: WidgetStatePropertyAll<Color>(colors.primary),
        foregroundColor: WidgetStatePropertyAll<Color>(colors.onPrimary),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: controlStyle.copyWith(
        foregroundColor: WidgetStatePropertyAll<Color>(colors.primary),
        backgroundColor: WidgetStatePropertyAll<Color>(colors.surface),
        side: WidgetStatePropertyAll<BorderSide>(outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: controlStyle.copyWith(
        foregroundColor: WidgetStatePropertyAll<Color>(colors.primary),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colors.onSurface,
        minimumSize: const Size(Sizes.minTapTarget, Sizes.minTapTarget),
        maximumSize: const Size(Sizes.minTapTarget, Sizes.minTapTarget),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        iconSize: Space.x6,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: colors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.x3,
        vertical: Space.x2,
      ),
      hintStyle: AppText.body.copyWith(color: colors.onSurface),
      labelStyle: AppText.label.copyWith(color: colors.onSurface),
      floatingLabelStyle: AppText.label.copyWith(color: colors.onSurface),
      errorStyle: AppText.caption.copyWith(color: colors.danger),
      border: _fieldBorder(outline),
      enabledBorder: _fieldBorder(outline),
      focusedBorder: _fieldBorder(outline),
      errorBorder: _fieldBorder(outline.copyWith(color: colors.danger)),
      focusedErrorBorder: _fieldBorder(outline.copyWith(color: colors.danger)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceVariant,
      selectedColor: colors.primary,
      disabledColor: colors.surfaceVariant,
      labelStyle: AppText.label.copyWith(color: colors.onSurface),
      secondaryLabelStyle: AppText.label.copyWith(color: colors.onPrimary),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x2,
        vertical: Space.x1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      // Chip layout includes stroke width, so the weight stays a hairline
      // in every mode; outdoor contrast still comes from [AppColors.outline]
      // (FE-THEME-03).
      side: BorderSide(
        color: colors.outline,
        width: Space.x0 / 2,
        strokeAlign: BorderSide.strokeAlignInside,
      ),
      elevation: 0,
      pressElevation: 0,
      shadowColor: const Color(0x00000000),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      elevation: 0,
      shadowColor: const Color(0x00000000),
      surfaceTintColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: outline,
      ),
      titleTextStyle: AppText.title.copyWith(color: colors.onSurface),
      contentTextStyle: AppText.body.copyWith(color: colors.onSurface),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      elevation: 0,
      shadowColor: const Color(0x00000000),
      surfaceTintColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.lg),
        ),
        side: outline,
      ),
      dragHandleColor: colors.outline,
      showDragHandle: true,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      shadowColor: const Color(0x00000000),
      surfaceTintColor: colors.surface,
      margin: const EdgeInsets.all(Space.x2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: outline,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colors.onSurface,
      textColor: colors.onSurface,
      titleTextStyle: AppText.bodyStrong.copyWith(color: colors.onSurface),
      subtitleTextStyle: AppText.caption.copyWith(color: colors.onSurface),
      minVerticalPadding: Space.x1,
      minLeadingWidth: Sizes.minTapTarget,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.x3,
        vertical: Space.x1,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      elevation: 0,
      shadowColor: const Color(0x00000000),
      surfaceTintColor: colors.surface,
      height: Sizes.minTapTarget + Space.x4,
      indicatorColor: colors.surfaceVariant,
      labelTextStyle: WidgetStatePropertyAll<TextStyle>(
        AppText.caption.copyWith(color: colors.onSurface),
      ),
      iconTheme: WidgetStatePropertyAll<IconThemeData>(
        IconThemeData(color: colors.onSurface, size: Space.x6),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colors.background,
      elevation: 0,
      minWidth: Sizes.minTapTarget + Space.x4,
      useIndicator: true,
      indicatorColor: colors.surfaceVariant,
      selectedLabelTextStyle: AppText.caption.copyWith(color: colors.onSurface),
      unselectedLabelTextStyle: AppText.caption.copyWith(
        color: colors.onSurface,
      ),
      selectedIconTheme: const IconThemeData(size: Space.x6),
      unselectedIconTheme: IconThemeData(
        size: Space.x6,
        color: colors.onSurface,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.outline,
      thickness: outline.width,
      space: Space.x4,
    ),
  );
}

AppColors _palette({required Brightness brightness, required bool outdoor}) {
  if (!outdoor) {
    return brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  }
  if (brightness == Brightness.light) {
    return AppColors.outdoor;
  }
  return AppColors.dark.copyWith(
    surface: AppColors.dark.background,
    surfaceVariant: AppColors.dark.background,
    outline: AppColors.dark.onSurface,
  );
}

ColorScheme _scheme(Brightness brightness, AppColors colors) {
  return ColorScheme(
    brightness: brightness,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    secondary: colors.secondary,
    onSecondary: _onFill(colors.secondary, colors),
    error: colors.danger,
    onError: _onFill(colors.danger, colors),
    surface: colors.surface,
    onSurface: colors.onSurface,
    surfaceContainerHighest: colors.surfaceVariant,
    onSurfaceVariant: colors.onSurface,
    outline: colors.outline,
    outlineVariant: colors.outline,
    shadow: const Color(0x00000000),
    scrim: const Color(0x00000000),
    surfaceTint: colors.surface,
    inverseSurface: colors.onSurface,
    onInverseSurface: colors.surface,
    inversePrimary: colors.secondary,
  );
}

TextTheme _textTheme(AppColors colors) {
  final Color ink = colors.onSurface;
  return TextTheme(
    displayLarge: AppText.display.copyWith(color: ink),
    headlineMedium: AppText.title.copyWith(color: ink),
    titleLarge: AppText.section.copyWith(color: ink),
    titleMedium: AppText.bodyStrong.copyWith(color: ink),
    bodyLarge: AppText.body.copyWith(color: ink),
    bodyMedium: AppText.body.copyWith(color: ink),
    bodySmall: AppText.caption.copyWith(color: ink),
    labelLarge: AppText.label.copyWith(color: ink),
    labelSmall: AppText.mono.copyWith(color: ink),
  );
}

BorderSide _outline(AppColors colors, bool outdoor) {
  return BorderSide(
    color: colors.outline,
    width: outdoor ? Space.x0 : Space.x0 / 2,
    strokeAlign: BorderSide.strokeAlignInside,
  );
}

OutlineInputBorder _fieldBorder(BorderSide side) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.md),
    borderSide: side,
  );
}

Color _onFill(Color fill, AppColors colors) {
  return fill.computeLuminance() < 0.5 ? colors.onPrimary : colors.onSurface;
}
