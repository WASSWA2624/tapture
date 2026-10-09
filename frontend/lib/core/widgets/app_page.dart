import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/app_icons.dart';

import 'app_header_title.dart';
import 'app_icon_button.dart';
import 'app_overflow_menu.dart';
import 'app_toolbar_scope.dart';
import 'responsive/breakpoints.dart';
import 'responsive/content_constraint.dart';
import 'responsive/viewport_metrics.dart';
import 'shell_header_scope.dart';
import 'trial_report_action.dart';

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
    this.headerTitle,
    this.headerDetail,
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

  /// Optional visible toolbar title; [title] remains the screen identity.
  final String? headerTitle;

  /// Optional secondary toolbar line, separate from the body [subtitle].
  final String? headerDetail;

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
  /// Tall action groups scroll within half the available viewport, leaving
  /// the body reachable on a short window or with enlarged text.
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

  /// The page's side margin for [context]'s size class. A body that owns its
  /// scrolling (`scrollable: false`) insets its own text and controls by this
  /// so every page lines up on the same edge (FE-RESP-02).
  static double gutter(BuildContext context) {
    return context.responsive(
      compact: Space.x4,
      medium: Space.x4,
      expanded: Space.x5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool shellOwns = ShellHeaderScope.ownsHeaderOf(context);
    final AppOverflowAction? trial = shellOwns
        ? null
        : trialReportAction(context);
    final List<AppOverflowAction> menu = <AppOverflowAction>[
      ...overflow,
      ?trial,
    ];
    final EdgeInsets padding = _paddingFor(context, inset: inset);
    final Widget content = scrollable
        ? _scrollingBody(context, padding)
        : _fixedBody(context, padding);
    final Widget? footer = this.footer;
    final Widget? leading = this.leading ?? _compactBack(context);
    final bool invertedBar = Theme.of(context).brightness != Brightness.dark;
    final List<Widget> barActions = <Widget>[
      ...actions,
      if (actions.isNotEmpty && menu.isNotEmpty)
        const SizedBox(width: Space.x2),
      if (menu.isNotEmpty)
        AppOverflowMenu(
          key: const ValueKey<String>('app-page-overflow'),
          items: menu,
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
              leading: leading == null
                  ? null
                  : Center(child: _barControl(context, leading)),
              leadingWidth: leading == null
                  ? null
                  : Sizes.minTapTarget + Space.x2,
              toolbarHeight: _toolbarHeight(
                context,
                leading,
                barActions.length,
              ),
              titleSpacing: leading == null
                  ? (compactBar ? Space.x2 : Space.x3)
                  : Space.x2,
              title: MediaQuery(
                data: MediaQuery.of(context),
                child: AppHeaderTitle(
                  title: headerTitle ?? title,
                  detail: headerDetail,
                  foregroundColor: Theme.of(
                    context,
                  ).appBarTheme.foregroundColor,
                ),
              ),
              actions: <Widget>[
                for (final Widget action in barActions)
                  _barControl(context, action),
              ],
            )
          : null,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SafeArea(bottom: footer == null, child: content),
            ),
            if (footer != null)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight / 2,
                ),
                child: SingleChildScrollView(
                  primary: false,
                  child: SafeArea(
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
                ),
              ),
          ],
        ),
      ),
    );
    if (!shellOwns) {
      return page;
    }
    return _PageHeaderRegistration(
      title: title,
      headerTitle: headerTitle,
      headerDetail: headerDetail,
      actions: actions,
      overflow: overflow,
      child: page,
    );
  }
}

extension on AppPage {
  // Material 3 icon buttons resolve their own theme ahead of AppBar's
  // IconTheme. Give toolbar controls the toolbar ink, while keeping the
  // shared disabled-state treatment and every other button property.
  Widget _barControl(BuildContext context, Widget child) {
    return AppToolbarScope(
      ink:
          Theme.of(context).appBarTheme.foregroundColor ??
          context.colors.onSurface,
      child: child,
    );
  }

  /// Reserve the actual scaled title height instead of clipping a long title
  /// to one toolbar line. Action slots keep their standard touch width.
  double _toolbarHeight(BuildContext context, Widget? leading, int actions) {
    final double minimum = compactBar
        ? Sizes.minTapTarget
        : Sizes.minTapTarget + Space.x2;
    final double width =
        (context.viewportSize.width -
                (leading == null ? 0 : Sizes.minTapTarget + Space.x2) -
                actions * Sizes.minTapTarget -
                Space.x6)
            .clamp(1, double.infinity)
            .toDouble();
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: headerTitle ?? title,
        style: Theme.of(context).appBarTheme.titleTextStyle ?? AppText.title,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width);
    double height = painter.height + Space.x2;
    painter.dispose();
    final String? detail = headerDetail;
    if (detail != null && detail.isNotEmpty) {
      final TextPainter detailPainter = TextPainter(
        text: TextSpan(text: detail, style: AppText.caption),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width);
      height += detailPainter.height;
      detailPainter.dispose();
    }
    return height < minimum ? minimum : height;
  }

  /// A back control when the route can pop: the same borderless arrow as a
  /// field's controls, so a compact header spends no weight on chrome. Null
  /// where there is nothing to go back to.
  Widget? _compactBack(BuildContext context) {
    if (!(ModalRoute.of(context)?.canPop ?? false)) {
      return null;
    }
    final String back = MaterialLocalizations.of(context).backButtonTooltip;
    return AppIconButton(
      icon: AppIcons.back,
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
  return EdgeInsets.symmetric(
    horizontal: AppPage.gutter(context),
    vertical: Space.x2,
  );
}

class _PageHeaderRegistration extends StatefulWidget {
  const _PageHeaderRegistration({
    required this.title,
    required this.headerTitle,
    required this.headerDetail,
    required this.actions,
    required this.overflow,
    required this.child,
  });

  final String title;
  final String? headerTitle;
  final String? headerDetail;
  final List<Widget> actions;
  final List<AppOverflowAction> overflow;
  final Widget child;

  @override
  State<_PageHeaderRegistration> createState() =>
      _PageHeaderRegistrationState();
}

class _PageHeaderRegistrationState extends State<_PageHeaderRegistration> {
  ModalRoute<Object?>? _route;
  State<ShellHeaderScope>? _headerScope;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _headerScope = context.findAncestorStateOfType<State<ShellHeaderScope>>();
    final ModalRoute<Object?>? next = ModalRoute.of(context);
    if (!identical(next, _route)) {
      _route?.animation?.removeStatusListener(_onStatus);
      _route = next;
      _route?.animation?.addStatusListener(_onStatus);
    }
    _schedule();
  }

  @override
  void didUpdateWidget(_PageHeaderRegistration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.headerTitle != widget.headerTitle ||
        oldWidget.headerDetail != widget.headerDetail ||
        !identical(oldWidget.actions, widget.actions) ||
        !identical(oldWidget.overflow, widget.overflow)) {
      _schedule();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _schedule();
    }
  }

  @override
  void dispose() {
    _route?.animation?.removeStatusListener(_onStatus);
    super.dispose();
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final ModalRoute<Object?>? route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) {
        return;
      }
      ShellHeaderScope.publish(
        context,
        owner: this,
        title: widget.title,
        headerTitle: widget.headerTitle,
        headerDetail: widget.headerDetail,
        actions: widget.actions,
        overflow: widget.overflow,
      );
    });
  }

  @override
  void deactivate() {
    final State<ShellHeaderScope>? scope = _headerScope;
    if (scope != null && scope.mounted) {
      ShellHeaderScope.release(scope.context, this);
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
