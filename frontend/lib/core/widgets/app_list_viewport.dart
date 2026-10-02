import 'package:flutter/material.dart';

/// Coordinates a list's controls with its bounded, virtualised content.
/// On a short viewport the header can scroll out of the way; the list keeps
/// its own lazy viewport instead of becoming an unbounded shrink-wrap list.
class AppListViewport extends StatelessWidget {
  /// Creates a coordinated header and bounded collection viewport.
  const AppListViewport({required this.header, required this.body, super.key});

  /// Search, filters or explanatory controls preceding the collection.
  final Widget header;

  /// A bounded list, or its loading, failure and empty panel.
  final Widget body;

  @override
  Widget build(BuildContext context) => PrimaryScrollController.none(
    // A shell, pane and page can each have a coordinated viewport. The
    // outer coordinator must not adopt another coordinator's inner controller:
    // attaching its position there creates a recursive detach/attach cycle.
    child: NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) =>
          <Widget>[SliverToBoxAdapter(child: header)],
      body: body,
    ),
  );
}
