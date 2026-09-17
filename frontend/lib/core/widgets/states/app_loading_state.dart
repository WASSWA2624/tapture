import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_card.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [AppSkeleton].
typedef AppLoadingState = AppSkeleton;

/// Placeholder sized to the real content, or a small inline spinner for
/// actions rather than a full-screen one.
class AppSkeleton extends StatelessWidget {
  /// Creates a block placeholder. [count] is how many units of [shape]
  /// to stack so arriving data does not jump the layout.
  const AppSkeleton({
    super.key,
    this.shape = SkeletonShape.list,
    this.count = 3,
  }) : _inline = false;

  /// Creates a compact spinner for a button row or trailing slot.
  const AppSkeleton.inline({super.key})
    : shape = SkeletonShape.list,
      count = 0,
      _inline = true;

  /// Which real layout this placeholder matches.
  final SkeletonShape shape;

  /// How many rows, cards or detail blocks to paint.
  final int count;

  final bool _inline;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    if (_inline) {
      return Semantics(
        label: Copy.loading,
        child: ExcludeSemantics(
          child: SizedBox(
            width: Space.x5,
            height: Space.x5,
            child: CircularProgressIndicator(
              strokeWidth: Space.x0,
              color: colors.primary,
              value: MediaQuery.disableAnimationsOf(context)
                  ? Space.x3 / Space.x4
                  : null,
            ),
          ),
        ),
      );
    }
    return Semantics(
      label: Copy.loading,
      child: ExcludeSemantics(
        child: switch (shape) {
          SkeletonShape.list => _ListSkeleton(colors: colors, count: count),
          SkeletonShape.card => _CardSkeleton(colors: colors, count: count),
          SkeletonShape.detail => _DetailSkeleton(colors: colors, count: count),
        },
      ),
    );
  }
}

/// Placeholder shapes sized to list rows, cards and a detail page.
enum SkeletonShape {
  /// [AppListTile]-tall rows.
  list,

  /// [AppCard]-sized blocks.
  card,

  /// A title plus body plus a large content well.
  detail,
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.colors, required this.count});

  final AppColors colors;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[for (int i = 0; i < count; i++) _listRow(colors)],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.colors, required this.count});

  final AppColors colors;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: Space.x3),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _bar(colors, height: Space.x5, width: Space.x12 * 4),
                const SizedBox(height: Space.x3),
                _bar(colors, height: Sizes.minTapTarget),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({required this.colors, required this.count});

  final AppColors colors;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: Space.x6),
          _bar(colors, height: Space.x8),
          const SizedBox(height: Space.x4),
          _bar(colors, height: Space.x4),
          const SizedBox(height: Space.x2),
          _bar(colors, height: Space.x4, width: Space.x12 * 5),
          const SizedBox(height: Space.x4),
          _bar(colors, height: Space.x12 * 2),
        ],
      ],
    );
  }
}

Widget _listRow(AppColors colors) {
  return ConstrainedBox(
    constraints: const BoxConstraints(minHeight: Sizes.minTapTarget + Space.x6),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x4,
        vertical: Space.x3,
      ),
      child: Row(
        children: <Widget>[
          _bar(colors, width: Space.x10, height: Space.x10, radius: Radii.pill),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _bar(colors, height: Space.x4),
                const SizedBox(height: Space.x2),
                _bar(colors, height: Space.x3, width: Space.x12 * 3),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _bar(
  AppColors colors, {
  required double height,
  double? width,
  double radius = Radii.sm,
}) {
  return SizedBox(
    width: width ?? double.infinity,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colors.outline,
          width: Space.x0 / 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
    ),
  );
}
