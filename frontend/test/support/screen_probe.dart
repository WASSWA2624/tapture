import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'text_contrast_probe.dart';

/// Shared assertions over the rendered production tree, never source claims.
abstract final class ScreenProbe {
  static List<String> layoutIssues(WidgetTester tester) {
    final List<String> issues = <String>[];
    Object? exception;
    while ((exception = tester.takeException()) != null) {
      issues.add(exception.toString());
    }
    for (final RenderParagraph paragraph in visibleParagraphs(tester)) {
      final Rect bounds = paragraph.localToGlobal(Offset.zero) & paragraph.size;
      if (paragraph.didExceedMaxLines) {
        issues.add(
          'Truncated label: ${paragraph.text.toPlainText()} at $bounds',
        );
      }
    }
    return issues;
  }

  /// Visible, laid-out paragraphs once each, including rich-text runs.
  static Iterable<RenderParagraph> visibleParagraphs(
    WidgetTester tester,
  ) sync* {
    final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final Rect viewport = Offset.zero & size;
    final Set<RenderParagraph> paragraphs = Set<RenderParagraph>.identity()
      ..addAll(tester.allRenderObjects.whereType<RenderParagraph>());
    for (final RenderParagraph paragraph in paragraphs) {
      if (!paragraph.attached || !paragraph.hasSize || !_painted(paragraph)) {
        continue;
      }
      final Rect bounds = paragraph.localToGlobal(Offset.zero) & paragraph.size;
      // A SliverPrototypeExtentList prototype is laid out only to measure the
      // row extent; it has no painted transform, so its position is NaN.
      if (bounds.isFinite && bounds.overlaps(viewport)) yield paragraph;
    }
  }

  /// Indexed-stack branches and faded InputDecorator labels are laid out but
  /// never painted. Their geometry cannot describe a visible clipped label.
  static bool _painted(RenderObject object) {
    for (
      RenderObject? parent = object;
      parent != null;
      parent = parent.parent
    ) {
      if (parent is RenderOffstage && parent.offstage) return false;
      if (parent is RenderSliverOffstage && parent.offstage) return false;
      if (parent is RenderOpacity && parent.opacity == 0) return false;
      if (parent is RenderAnimatedOpacity && parent.opacity.value == 0) {
        return false;
      }
      if (parent is RenderSliverOpacity && parent.opacity == 0) return false;
      if (parent is RenderSliverAnimatedOpacity && parent.opacity.value == 0) {
        return false;
      }
    }
    return true;
  }

  /// With [targets], check tap sizes as each complete control is brought into
  /// view. A cropped neighbour is checked on its own visit, rather than using
  /// its clipped semantics rectangle as its full tap target. Layout, labels
  /// and painted contrast still cover the whole visible tree.
  static Future<List<String>> accessibilityIssues(
    WidgetTester tester, {
    List<Finder>? targets,
  }) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final List<String> issues = layoutIssues(tester);
      final Set<int>? nodes = targets == null ? null : <int>{};
      if (targets != null) {
        if (targets.isEmpty) {
          issues.add('No accessibility targets were supplied');
        }
        for (final Finder target in targets) {
          if (target.evaluate().length != 1) {
            issues.add('Expected one accessibility target: $target');
            continue;
          }
          final RenderObject render = tester.renderObject(target);
          if (render is! RenderBox || !render.hasSize || !_painted(render)) {
            issues.add(
              'Accessibility target is not painted and laid out: $target',
            );
            continue;
          }
          final Rect bounds = MatrixUtils.transformRect(
            render.getTransformTo(null),
            render.paintBounds,
          );
          final view = tester.viewOf(target);
          Rect viewport =
              Offset.zero & (view.physicalSize / view.devicePixelRatio);
          for (
            RenderObject? parent = render.parent;
            parent != null;
            parent = parent.parent
          ) {
            if (parent is RenderAbstractViewport) {
              viewport = viewport.intersect(
                MatrixUtils.transformRect(
                  parent.getTransformTo(null),
                  parent.paintBounds,
                ),
              );
            }
          }
          if (!bounds.isFinite ||
              bounds.left < viewport.left - precisionErrorTolerance ||
              bounds.top < viewport.top - precisionErrorTolerance ||
              bounds.right > viewport.right + precisionErrorTolerance ||
              bounds.bottom > viewport.bottom + precisionErrorTolerance) {
            issues.add(
              'Accessibility target paint $bounds is clipped by $viewport: $target',
            );
          }
          const MinimumTapTargetGuideline minimum =
              androidTapTargetGuideline as MinimumTapTargetGuideline;
          if (bounds.width < minimum.size.width - precisionErrorTolerance ||
              bounds.height < minimum.size.height - precisionErrorTolerance) {
            issues.add(
              'Accessibility target paint $bounds is below ${minimum.size}: $target',
            );
          }
          final Set<int> targetNodes = <int>{};
          void include(SemanticsNode node) {
            if (!targetNodes.add(node.id)) return;
            node.visitChildren((SemanticsNode child) {
              include(child);
              return true;
            });
          }

          void visit(RenderObject object) {
            if (object.debugSemantics case final SemanticsNode node) {
              include(node);
            }
            object.visitChildren(visit);
          }

          // getSemantics walks up to an ancestor when a wrapper owns no node;
          // that can accidentally select the entire scrolling screen. Keep
          // this scope inside the chosen control's rendered subtree instead.
          visit(render);
          if (targetNodes.isEmpty) {
            issues.add('Accessibility target has no semantics: $target');
          }
          nodes!.addAll(targetNodes);
        }
      }
      for (final AccessibilityGuideline guideline in <AccessibilityGuideline>[
        for (final AccessibilityGuideline minimum in <AccessibilityGuideline>[
          androidTapTargetGuideline,
          iOSTapTargetGuideline,
        ])
          nodes == null
              ? minimum
              : _ScopedTapTargetGuideline(
                  minimum as MinimumTapTargetGuideline,
                  nodes,
                ),
        labeledTapTargetGuideline,
      ]) {
        final Evaluation result = await guideline.evaluate(tester);
        if (!result.passed) {
          issues.add('${guideline.description}: ${result.reason}');
        }
      }
      issues.addAll(TextContrastProbe.issues(visibleParagraphs(tester)));
      return issues;
    } finally {
      semantics.dispose();
    }
  }
}

final class _ScopedTapTargetGuideline extends MinimumTapTargetGuideline {
  _ScopedTapTargetGuideline(MinimumTapTargetGuideline guideline, this._nodes)
    : super(size: guideline.size, link: guideline.link);

  final Set<int> _nodes;

  @override
  bool shouldSkipNode(SemanticsNode node) =>
      !_nodes.contains(node.id) || super.shouldSkipNode(node);
}
