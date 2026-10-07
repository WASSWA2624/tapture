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

  static Future<List<String>> accessibilityIssues(WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final List<String> issues = layoutIssues(tester);
      for (final AccessibilityGuideline guideline in <AccessibilityGuideline>[
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
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
