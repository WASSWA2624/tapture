import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uses the SDK contrast sampler without its premature web image disposal.
///
/// Flutter 3.44's MinimumTextContrastGuideline disposes the screenshot before
/// reading its dimensions. CanvasKit rejects that read. The custom SDK
/// evaluator keeps the image alive, with the same histogram and tolerance.
/// Eligibility and WCAG thresholds below match the minimum-text evaluator.
/// If smoothing makes the SDK choose an edge colour instead of solid ink,
/// opaque plain text can use ink observed within its painted line boxes and
/// a dominant captured background. Unsupported or ambiguous samples still fail.
/// https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
final class BrowserTextContrastGuideline extends MinimumTextContrastGuideline {
  const BrowserTextContrastGuideline();

  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    final Map<double, Set<Element>> groups = <double, Set<Element>>{};
    for (final RenderView view in tester.binding.renderViews) {
      _collect(view.owner!.semanticsOwner!.rootSemanticsNode!, view, groups);
    }
    Evaluation result = const Evaluation.pass();
    final Map<ui.FlutterView, _ContrastPixels?> snapshots =
        <ui.FlutterView, _ContrastPixels?>{};
    for (final MapEntry<double, Set<Element>> group in groups.entries) {
      result += await _evaluateGroup(tester, group.value, group.key, snapshots);
    }
    return result;
  }

  Future<Evaluation> _evaluateGroup(
    WidgetTester tester,
    Set<Element> elements,
    double ratio,
    Map<ui.FlutterView, _ContrastPixels?> snapshots,
  ) async {
    final CustomMinimumContrastGuideline sdk = CustomMinimumContrastGuideline(
      finder: find.byElementPredicate(elements.contains),
      minimumRatio: ratio,
      description: description,
    );
    final Evaluation original = await sdk.evaluate(tester);
    if (original.passed) return original;
    if (elements.length == 1) {
      final double? painted = await _paintedInkRatio(
        tester,
        elements.single,
        snapshots,
      );
      return painted != null && painted >= sdk.minimumRatio - sdk.tolerance
          ? const Evaluation.pass()
          : original;
    }
    // Split only a failing group; passing branches retain the SDK result.
    // This identifies each failing element without rasterising every label.
    final List<Element> ordered = elements.toList();
    final int middle = ordered.length ~/ 2;
    return await _evaluateGroup(
          tester,
          ordered.take(middle).toSet(),
          ratio,
          snapshots,
        ) +
        await _evaluateGroup(
          tester,
          ordered.skip(middle).toSet(),
          ratio,
          snapshots,
        );
  }

  Future<double?> _paintedInkRatio(
    WidgetTester tester,
    Element element,
    Map<ui.FlutterView, _ContrastPixels?> snapshots,
  ) async {
    final Widget widget = element.widget;
    final RenderObject? render = element.renderObject;
    if (widget is! Text || widget.data == null || render is! RenderParagraph) {
      return null;
    }
    final TextStyle style = _effectiveStyle(element);
    final Color? ink = style.color;
    if (style.foreground != null ||
        ink == null ||
        ink.a != 1 ||
        ink.colorSpace != ui.ColorSpace.sRGB ||
        !_hasUniformPaintAncestry(element, render)) {
      return null;
    }
    final ui.FlutterView view = tester.viewOf(
      find.byElementPredicate(
        (Element candidate) => identical(candidate, element),
      ),
    );
    if (!snapshots.containsKey(view)) {
      snapshots[view] = await _capturePixels(tester, view);
    }
    final _ContrastPixels? pixels = snapshots[view];
    if (pixels == null) return null;
    final List<ui.TextBox> boxes = render.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: widget.data!.length),
    );
    final Map<int, int> histogram = <int, int>{};
    final Set<int> sampled = <int>{};
    for (final ui.TextBox box in boxes) {
      final Rect bounds = MatrixUtils.transformRect(
        render.getTransformTo(null),
        box.toRect(),
      );
      final Rect surface = Rect.fromLTWH(
        0,
        0,
        pixels.width.toDouble(),
        pixels.height.toDouble(),
      );
      if (bounds.isEmpty || bounds != bounds.intersect(surface)) return null;
      for (int y = bounds.top.floor(); y < bounds.bottom.ceil(); y++) {
        for (int x = bounds.left.floor(); x < bounds.right.ceil(); x++) {
          final int offset = y * pixels.width + x;
          if (!sampled.add(offset)) continue;
          final int rgba = pixels.data.getUint32(offset * 4);
          histogram.update(rgba, (int count) => count + 1, ifAbsent: () => 1);
        }
      }
    }
    final int argb = ink.toARGB32();
    final int rgbaInk = ((argb & 0x00ffffff) << 8) | (argb >> 24);
    if ((histogram[rgbaInk] ?? 0) == 0) return null;
    final MapEntry<int, int> background = histogram.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    if (background.key == rgbaInk ||
        (background.key & 0xff) != 0xff ||
        background.value * 2 <= sampled.length) {
      return null;
    }
    final Color behind = Color(
      ((background.key << 24) | (background.key >> 8)) & 0xffffffff,
    );
    final double first = ink.computeLuminance();
    final double second = behind.computeLuminance();
    final double light = first > second ? first : second;
    final double dark = first < second ? first : second;
    return (light + 0.05) / (dark + 0.05);
  }

  bool _hasUniformPaintAncestry(Element element, RenderParagraph paragraph) {
    bool supported = true;
    element.visitAncestorElements((Element ancestor) {
      final Widget widget = ancestor.widget;
      if (widget is ShaderMask ||
          widget is ColorFiltered ||
          widget is BackdropFilter ||
          widget is ImageFiltered ||
          (widget is CustomPaint &&
              (widget.painter != null || widget.foregroundPainter != null))) {
        supported = false;
      }
      return supported;
    });
    if (!supported) return false;
    RenderObject? ancestor = paragraph.parent;
    while (ancestor != null) {
      if ((ancestor is RenderOpacity && ancestor.opacity < 1) ||
          (ancestor is RenderAnimatedOpacity && ancestor.opacity.value < 1) ||
          (ancestor is RenderSliverOpacity && ancestor.opacity < 1) ||
          (ancestor is RenderSliverAnimatedOpacity &&
              ancestor.opacity.value < 1) ||
          ancestor is RenderShaderMask ||
          ancestor is RenderBackdropFilter) {
        return false;
      }
      if (ancestor is RenderDecoratedBox) {
        final Decoration decoration = ancestor.decoration;
        final bool uniform = switch (decoration) {
          BoxDecoration() =>
            decoration.gradient == null &&
                decoration.image == null &&
                (decoration.boxShadow?.isEmpty ?? true),
          ShapeDecoration() =>
            decoration.gradient == null &&
                decoration.image == null &&
                (decoration.shadows?.isEmpty ?? true),
          _ => false,
        };
        if (!uniform) return false;
      }
      ancestor = ancestor.parent;
    }
    return true;
  }

  Future<_ContrastPixels?> _capturePixels(
    WidgetTester tester,
    ui.FlutterView view,
  ) async {
    final RenderView renderView = tester.binding.renderViews.firstWhere(
      (RenderView candidate) => candidate.flutterView == view,
    );
    return tester.runAsync<_ContrastPixels?>(() async {
      final ui.Image image = await (renderView.debugLayer! as OffsetLayer)
          .toImage(
            renderView.paintBounds,
            pixelRatio: 1 / view.devicePixelRatio,
          );
      try {
        final ByteData? data = await image.toByteData();
        return data == null
            ? null
            : _ContrastPixels(image.width, image.height, data);
      } finally {
        image.dispose();
      }
    });
  }

  void _collect(
    SemanticsNode node,
    RenderView view,
    Map<double, Set<Element>> groups,
  ) {
    if (node.isInvisible ||
        node.isMergedIntoParent ||
        node.flagsCollection.isHidden ||
        node.flagsCollection.isEnabled == ui.Tristate.isFalse) {
      return;
    }
    node.visitChildren((SemanticsNode child) {
      _collect(child, view, groups);
      return true;
    });
    final SemanticsData data = node.getSemanticsData();
    if (shouldSkipNode(data)) return;
    final String text = data.label.isEmpty ? data.value : data.label;
    for (final Element element in find.text(text).hitTestable().evaluate()) {
      final RenderObject? render = element.renderObject;
      if (render is! RenderBox) {
        throw StateError('Unexpected contrast render object: $render');
      }
      if (!_intersects(node, render, view) ||
          isNodeOffScreen(
            MatrixUtils.transformRect(
              render.getTransformTo(null),
              render.paintBounds.inflate(4),
            ),
            view.flutterView,
          )) {
        continue;
      }
      final TextStyle style = _effectiveStyle(element);
      final double ratio = targetContrastRatio(
        style.fontSize,
        bold: style.fontWeight == FontWeight.bold,
      );
      (groups[ratio] ??= <Element>{}).add(element);
    }
  }

  TextStyle _effectiveStyle(Element element) {
    final Widget widget = element.widget;
    if (widget is EditableText) return widget.style;
    if (widget is Text) {
      final TextStyle? style = widget.style;
      return style == null || style.inherit
          ? DefaultTextStyle.of(element).style.merge(style)
          : style;
    }
    throw StateError('Unexpected contrast widget: ${widget.runtimeType}');
  }

  bool _intersects(SemanticsNode node, RenderBox render, RenderView view) {
    final Matrix4 transform = Matrix4.identity();
    view.applyPaintTransform(view.child!, transform);
    transform.multiply(render.getTransformTo(null));
    final Rect screenBounds = MatrixUtils.transformRect(
      transform,
      render.paintBounds,
    );
    Rect nodeBounds = node.rect;
    SemanticsNode? current = node;
    while (current != null) {
      if (current.transform case final Matrix4 transform) {
        nodeBounds = MatrixUtils.transformRect(transform, nodeBounds);
      }
      current = current.parent;
    }
    final Rect intersection = nodeBounds.intersect(screenBounds);
    return intersection.width > 0 && intersection.height > 0;
  }
}

final class _ContrastPixels {
  const _ContrastPixels(this.width, this.height, this.data);

  final int width;
  final int height;
  final ByteData data;
}
