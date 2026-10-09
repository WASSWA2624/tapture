import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'text_contrast_probe.dart';

/// Shared assertions over the rendered production tree, never source claims.
abstract final class ScreenProbe {
  /// The portion a scrollable composition currently allows a control to paint.
  /// Every enclosing viewport participates, including nested page/shell views.
  static Rect targetViewport(WidgetTester tester, Finder target) {
    final RenderObject render = tester.renderObject(target);
    final view = tester.viewOf(target);
    Rect viewport = Offset.zero & (view.physicalSize / view.devicePixelRatio);
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
    return viewport;
  }

  /// A naturally tall control must still expose a usable 48dp interactive area.
  /// This does not replace complete-control checks or prove label reachability.
  static List<String> reachabilityIssues(WidgetTester tester, Finder target) {
    if (target.evaluate().length != 1) {
      return <String>['Expected one reachable target: $target'];
    }
    final RenderObject render = tester.renderObject(target);
    if (render is! RenderBox || !render.hasSize || !_painted(render)) {
      return <String>['Reachable target is not painted and laid out: $target'];
    }
    final Rect bounds = MatrixUtils.transformRect(
      render.getTransformTo(null),
      render.paintBounds,
    );
    final Rect viewport = targetViewport(tester, target);
    final Rect region = bounds.intersect(viewport);
    const MinimumTapTargetGuideline minimum =
        androidTapTargetGuideline as MinimumTapTargetGuideline;
    if (!bounds.isFinite ||
        !viewport.isFinite ||
        !bounds.overlaps(viewport) ||
        region.width < minimum.size.width - precisionErrorTolerance ||
        region.height < minimum.size.height - precisionErrorTolerance) {
      return <String>[
        'Interactive painted region $region is below ${minimum.size}: $target',
      ];
    }
    return const <String>[];
  }

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
  /// [within] bounds label and contrast checks to one production composition;
  /// layout exceptions remain global and omitted scopes keep existing checks.
  /// [reachableTargets] is mutually exclusive with [targets]. It additionally
  /// supports naturally tall controls through their painted interactive area;
  /// callers must prove full text reachability and actual interaction separately.
  static Future<List<String>> accessibilityIssues(
    WidgetTester tester, {
    List<Finder>? targets,
    List<Finder>? reachableTargets,
    Finder? within,
  }) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final List<String> issues = layoutIssues(tester);
      if (targets != null && reachableTargets != null) {
        issues.add(
          'Supply either strict targets or reachableTargets, never both',
        );
        return issues;
      }
      RenderObject? scope;
      if (within != null) {
        if (within.evaluate().length != 1) {
          issues.add('Expected one accessibility scope: $within');
          return issues;
        }
        scope = tester.renderObject(within);
      }
      final Set<SemanticsNode>? scopeNodes = scope == null
          ? null
          : _semanticsWithin(scope);
      final List<Finder>? selectedTargets = targets ?? reachableTargets;
      final Set<int>? nodes = selectedTargets == null
          ? scopeNodes?.map((SemanticsNode node) => node.id).toSet()
          : <int>{};
      if (selectedTargets != null) {
        if (selectedTargets.isEmpty) {
          issues.add('No accessibility targets were supplied');
        }
        for (final Finder target in selectedTargets) {
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
          final Rect viewport = targetViewport(tester, target);
          if (reachableTargets != null) {
            issues.addAll(reachabilityIssues(tester, target));
          } else if (!bounds.isFinite ||
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
          // getSemantics walks up to an ancestor when a wrapper owns no node;
          // that can accidentally select the entire scrolling screen. Keep
          // this scope inside the chosen control's rendered subtree instead.
          final Set<int> targetNodes = _semanticsWithin(
            render,
          ).map((SemanticsNode node) => node.id).toSet();
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
        if (scopeNodes == null) labeledTapTargetGuideline,
      ]) {
        final Evaluation result = await guideline.evaluate(tester);
        if (!result.passed) {
          issues.add('${guideline.description}: ${result.reason}');
        }
      }
      if (scopeNodes != null) {
        if (scopeNodes.isEmpty) {
          issues.add('Accessibility scope has no semantics: $within');
        }
        for (final SemanticsNode node in scopeNodes) {
          if (node.isMergedIntoParent ||
              node.isInvisible ||
              node.flagsCollection.isHidden ||
              node.flagsCollection.isTextField) {
            continue;
          }
          final SemanticsData data = node.getSemanticsData();
          if ((data.hasAction(ui.SemanticsAction.tap) ||
                  data.hasAction(ui.SemanticsAction.longPress)) &&
              data.label.isEmpty &&
              data.tooltip.isEmpty) {
            issues.add(
              'Tappable widgets should have a semantic label: $node: expected tappable node to have semantic label, but none was found.',
            );
          }
        }
      }
      issues.addAll(
        TextContrastProbe.issues(
          visibleParagraphs(tester).where(
            (RenderParagraph paragraph) =>
                scope == null || _descendsFrom(paragraph, scope),
          ),
        ),
      );
      return issues;
    } finally {
      semantics.dispose();
    }
  }

  static Set<SemanticsNode> _semanticsWithin(RenderObject scope) {
    final Set<SemanticsNode> nodes = Set<SemanticsNode>.identity();
    void include(SemanticsNode node) {
      if (!nodes.add(node)) return;
      node.visitChildren((SemanticsNode child) {
        include(child);
        return true;
      });
    }

    void visit(RenderObject object) {
      if (object.debugSemantics case final SemanticsNode node) include(node);
      object.visitChildren(visit);
    }

    visit(scope);
    return nodes;
  }

  static bool _descendsFrom(RenderObject object, RenderObject scope) {
    for (
      RenderObject? parent = object;
      parent != null;
      parent = parent.parent
    ) {
      if (identical(parent, scope)) return true;
    }
    return false;
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
