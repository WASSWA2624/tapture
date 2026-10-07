import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Measures the resolved text paints rather than anti-aliased edge pixels.
/// WCAG 1.4.3 requires the user agent's foreground/background colours:
/// https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
abstract final class TextContrastProbe {
  /// All contrast failures, including separate styled runs in rich text.
  static List<String> issues(Iterable<RenderParagraph> paragraphs) {
    final List<String> found = <String>[];
    for (final RenderParagraph paragraph in paragraphs) {
      if (_disabled(paragraph)) continue;
      for (final _TextRun run in _runs(paragraph.text, const TextStyle())) {
        final Color? foreground =
            run.style.foreground?.color ?? run.style.color;
        if (foreground == null || run.style.foreground?.shader != null) {
          found.add('Text contrast cannot resolve the paint: ${run.text}');
          continue;
        }
        Color ink = foreground;
        Color background =
            run.style.background?.color ??
            run.style.backgroundColor ??
            const Color(0x00000000);
        bool unresolved = false;
        for (
          RenderObject? parent = paragraph;
          parent != null;
          parent = parent.parent
        ) {
          final Color? surface = _surface(parent);
          if (surface != null) {
            ink = Color.alphaBlend(ink, surface);
            background = Color.alphaBlend(background, surface);
          }
          if (parent is RenderDecoratedBox &&
              parent.decoration is BoxDecoration &&
              (parent.decoration as BoxDecoration).gradient != null) {
            unresolved = true;
          }
          final double opacity = _opacity(parent);
          if (opacity != 1) {
            ink = ink.withValues(alpha: ink.a * opacity);
            background = background.withValues(alpha: background.a * opacity);
          }
        }
        if (unresolved || background.a < 1) {
          found.add('Text contrast cannot resolve the background: ${run.text}');
          continue;
        }
        final double first = ink.computeLuminance();
        final double second = background.computeLuminance();
        final double ratio =
            (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
        final double size = paragraph.textScaler.scale(
          run.style.fontSize ?? 14,
        );
        final bool bold =
            (run.style.fontWeight?.value ?? 400) >= FontWeight.w700.value;
        // Flutter logical pixels use the CSS-pixel equivalent of 18pt/14pt.
        final double minimum = size >= 24 || (bold && size >= 56 / 3) ? 3 : 4.5;
        if (ratio < minimum) {
          final Rect bounds =
              paragraph.localToGlobal(Offset.zero) & paragraph.size;
          found.add(
            'Text contrast: ${run.text} at $bounds; '
            '${ratio.toStringAsFixed(3)}:1 below $minimum:1 '
            '(foreground ${ink.toARGB32().toRadixString(16)}, '
            'background ${background.toARGB32().toRadixString(16)})',
          );
        }
      }
    }
    return found;
  }

  static Iterable<_TextRun> _runs(InlineSpan span, TextStyle inherited) sync* {
    if (span is! TextSpan) return;
    final TextStyle style = inherited.merge(span.style);
    final String text = span.text ?? '';
    if (text.trim().isNotEmpty) yield (text: text, style: style);
    for (final InlineSpan child in span.children ?? const <InlineSpan>[]) {
      yield* _runs(child, style);
    }
  }

  static Color? _surface(RenderObject object) {
    if (object is RenderPhysicalModel) return object.color;
    if (object is RenderPhysicalShape) return object.color;
    if (object is RenderDecoratedBox) {
      final Decoration decoration = object.decoration;
      if (decoration is BoxDecoration) return decoration.color;
      if (decoration is ShapeDecoration) return decoration.color;
    }
    // ColoredBox's renderer is private; inspect the public widget that owns
    // this paint instead of coupling the guardrail to its private class name.
    final Object? creator = object.debugCreator;
    if (creator is DebugCreator && creator.element.widget is ColoredBox) {
      return (creator.element.widget as ColoredBox).color;
    }
    return null;
  }

  static double _opacity(RenderObject object) => switch (object) {
    RenderOpacity() => object.opacity,
    RenderAnimatedOpacity() => object.opacity.value,
    RenderSliverOpacity() => object.opacity,
    RenderSliverAnimatedOpacity() => object.opacity.value,
    _ => 1,
  };

  static bool _disabled(RenderObject object) {
    for (
      RenderObject? parent = object;
      parent != null;
      parent = parent.parent
    ) {
      final Object? creator = parent.debugCreator;
      if (creator is DebugCreator && creator.element.widget is Semantics) {
        final Semantics semantics = creator.element.widget as Semantics;
        if (semantics.properties.enabled == false) return true;
      }
    }
    return false;
  }
}

typedef _TextRun = ({String text, TextStyle style});
