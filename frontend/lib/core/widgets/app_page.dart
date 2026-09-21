import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';

import 'app_icon_button.dart';
import 'app_overflow_menu.dart';
import 'responsive/breakpoints.dart';
import 'responsive/content_constraint.dart';
import 'shell_header_scope.dart';

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
    this.overflow = const <AppOverflowAction>[],
    this.footer,
    this.onRefresh,
    this.showAppBar = true,
    this.inset = true,
    this.leading,
    this.scrollable = true,
    this.compactBar = false,
  });

  /// App bar title.
  final String title;

  /// Optional line under the title, inside the scrolling column so 200
  /// percent text scale cannot clip the bar (FE-A11Y-03).
  final String? subtitle;

  /// Icon-only app-bar actions. Visible chrome must not show a text label;
  /// labelled commands belong in [overflow] (FE-A11Y-01, FE-A11Y-02).
  final List<Widget> actions;

  /// Labelled commands behind the trailing three-dot control.
  final List<AppOverflowAction> overflow;

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

  /// When false, list-style pages bleed to the edges like a chat list.
  final bool inset;

  /// When false, [body] gets the whole height between the bar and the
  /// [footer] and scrolls itself, so it can pin its own actions: an
  /// [AppForm] keeps its submit bar in reach this way (FE-SIMP-01).
  final bool scrollable;

  /// When true, the app bar is one 48dp row with no extra padding, for
  /// overlay-style screens that should not spend height on chrome.
  final bool compactBar;

  @override
  Widget build(BuildContext context) {
    final bool shellOwns = ShellHeaderScope.ownsHeaderOf(context);
    final EdgeInsets padding = _paddingFor(context, inset: inset);
    final Widget content = scrollable
        ? _scrollingBody(context, padding)
        : _fixedBody(context, padding);
    final Widget? footer = this.footer;
    final Widget? leading = this.leading ?? _compactBack(context);
    final bool invertedBar = Theme.of(context).brightness != Brightness.dark;
    final List<Widget> barActions = <Widget>[
      ...actions,
      if (actions.isNotEmpty && overflow.isNotEmpty)
        const SizedBox(width: Space.x2),
      if (overflow.isNotEmpty)
        AppOverflowMenu(
          key: const ValueKey<String>('app-page-overflow'),
          items: overflow,
          inverted: invertedBar,
        ),
    ];
    final Widget page = Scaffold(
      backgroundColor: inset
          ? context.colors.background
          : context.colors.surface,
      resizeToAvoidBottomInset: true,
      appBar: showAppBar && !shellOwns
          ? AppBar(
              automaticallyImplyLeading: leading == null,
              leading: leading == null ? null : Center(child: leading),
              leadingWidth: leading == null
                  ? null
                  : Sizes.minTapTarget + Space.x2,
              toolbarHeight: compactBar
                  ? Sizes.minTapTarget
                  : Sizes.minTapTarget + Space.x2,
              titleSpacing: leading == null
                  ? (compactBar ? Space.x2 : Space.x3)
                  : Space.x2,
              title: Text(title),
              actions: barActions,
            )
          : null,
      body: Column(
        children: <Widget>[
          Expanded(
            child: SafeArea(bottom: footer == null, child: content),
          ),
          if (footer != null)
            SafeArea(
              top: false,
              child: Padding(
                // Inset even on edge-to-edge pages: a pinned action never
                // touches the screen edge.
                padding: _paddingFor(
                  context,
                  inset: true,
                ).copyWith(top: compactBar ? Space.x1 : Space.x2),
                child: ContentConstraint(child: footer),
              ),
            ),
        ],
      ),
    );
    if (!shellOwns) {
      return page;
    }
    return _PageHeaderRegistration(
      title: title,
      actions: actions,
      overflow: overflow,
      child: page,
    );
  }
}

extension on AppPage {
  /// A back control when the route can pop: the same borderless arrow as a
  /// field's controls, so a compact header spends no weight on chrome. Null
  /// where there is nothing to go back to.
  Widget? _compactBack(BuildContext context) {
    if (!(ModalRoute.of(context)?.canPop ?? false)) {
      return null;
    }
    final String back = MaterialLocalizations.of(context).backButtonTooltip;
    return AppIconButton(
      icon: Icons.arrow_back,
      semanticLabel: back,
      tooltip: back,
      outlined: false,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }

  /// [body] in the page's own scroll view, under an optional [subtitle].
  Widget _scrollingBody(BuildContext context, EdgeInsets padding) {
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
    return scroller;
  }

  /// [body] under an optional [subtitle], given the remaining height.
  Widget _fixedBody(BuildContext context, EdgeInsets padding) {
    final String? subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (subtitle != null)
          Padding(
            padding: padding.copyWith(bottom: Space.x0),
            child: ContentConstraint(
              child: Text(
                subtitle,
                style: AppText.caption.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ),
        Expanded(child: body),
      ],
    );
  }
}

EdgeInsets _paddingFor(BuildContext context, {required bool inset}) {
  if (!inset) {
    return const EdgeInsets.symmetric(vertical: Space.x1);
  }
  final double horizontal = context.responsive(
    compact: Space.x4,
    medium: Space.x4,
    expanded: Space.x5,
  );
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: Space.x2);
}

class _PageHeaderRegistration extends StatefulWidget {
  const _PageHeaderRegistration({
    required this.title,
    required this.actions,
    required this.overflow,
    required this.child,
  });

  final String title;
  final List<Widget> actions;
  final List<AppOverflowAction> overflow;
  final Widget child;

  @override
  State<_PageHeaderRegistration> createState() =>
      _PageHeaderRegistrationState();
}

class _PageHeaderRegistrationState extends State<_PageHeaderRegistration> {
  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_PageHeaderRegistration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        !identical(oldWidget.actions, widget.actions) ||
        !identical(oldWidget.overflow, widget.overflow)) {
      _schedule();
    }
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ShellHeaderScope.publish(
        context,
        owner: this,
        title: widget.title,
        actions: widget.actions,
        overflow: widget.overflow,
      );
    });
  }

  @override
  void deactivate() {
    ShellHeaderScope.release(context, this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
