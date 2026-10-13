import 'package:flutter/widgets.dart';

import 'app_page_layout.dart';

/// Shares a page's composition with catalogue controls without copying state.
class AppPageLayoutScope extends InheritedWidget {
  /// Overrides presentation only; values, focus and navigation remain owned.
  const AppPageLayoutScope({
    super.key,
    required this.layout,
    required super.child,
  });

  /// The selected composition for descendants.
  final AppPageLayout layout;

  /// Uses Essentials when a catalogue control is outside a project page.
  static AppPageLayout of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppPageLayoutScope>()
          ?.layout ??
      AppPageLayout.essentials;

  @override
  bool updateShouldNotify(AppPageLayoutScope oldWidget) =>
      oldWidget.layout != layout;
}
