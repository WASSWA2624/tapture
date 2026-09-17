import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';

import 'responsive/breakpoints.dart';
import 'responsive/content_constraint.dart';

/// The single page frame every screen composes: app bar, body, optional
/// footer, safe-area and keyboard insets, and scrolling (FE-RESP-06,
/// FE-RESP-08).
class AppPage extends StatelessWidget {
  /// Creates a page. Pull-to-refresh is attached only when [onRefresh] is
  /// given.
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const <Widget>[],
    this.footer,
    this.onRefresh,
    this.showAppBar = true,
    this.leading,
  });

  /// App bar title.
  final String title;

  /// Optional line under the title, inside the scrolling column so 200
  /// percent text scale cannot clip the bar (FE-A11Y-03).
  final String? subtitle;

  /// App bar actions. Each control the caller passes must already meet 48dp
  /// and carry a label (FE-A11Y-01, FE-A11Y-02).
  final List<Widget> actions;

  /// Page content. This widget owns scrolling, so [body] is not itself a
  /// scroll view.
  final Widget body;

  /// Optional action slot pinned above the keyboard and the gesture bar.
  final Widget? footer;

  /// When set, the body can be pulled to refresh. Omitted, there is no
  /// indicator.
  final Future<void> Function()? onRefresh;

  /// Optional control before the title (brand mark, back is implied).
  final Widget? leading;

  /// When false, the page sits under shell chrome that already has a header.
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = _paddingFor(context);
    Widget scroller = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: padding,
      child: ContentConstraint(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (subtitle != null) ...<Widget>[
              Text(
                subtitle!,
                style: AppText.caption.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: Space.x2),
            ],
            body,
          ],
        ),
      ),
    );
    final Future<void> Function()? refresh = onRefresh;
    if (refresh != null) {
      scroller = RefreshIndicator(onRefresh: refresh, child: scroller);
    }
    final Widget? footer = this.footer;
    final Widget? leading = this.leading;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: showAppBar
          ? AppBar(
              automaticallyImplyLeading: leading == null,
              leading: leading == null ? null : Center(child: leading),
              leadingWidth: leading == null
                  ? null
                  : Sizes.minTapTarget + Space.x2,
              titleSpacing: leading == null ? Space.x3 : Space.x2,
              title: Text(title),
              actions: actions,
            )
          : null,
      body: Column(
        children: <Widget>[
          Expanded(
            child: SafeArea(bottom: footer == null, child: scroller),
          ),
          if (footer != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: padding.copyWith(top: Space.x2),
                child: ContentConstraint(child: footer),
              ),
            ),
        ],
      ),
    );
  }
}

EdgeInsets _paddingFor(BuildContext context) {
  final double horizontal = context.responsive(
    compact: Space.x4,
    medium: Space.x4,
    expanded: Space.x5,
  );
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: Space.x2);
}
