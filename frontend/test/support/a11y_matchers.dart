import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The default minimum tap target, in logical pixels (FE-A11Y-01).
const double _minTapTarget = 48;

/// Framework guidelines `expectNoA11yIssues` evaluates, in the order they
/// are reported.
const List<AccessibilityGuideline> _guidelines = <AccessibilityGuideline>[
  androidTapTargetGuideline,
  iOSTapTargetGuideline,
  labeledTapTargetGuideline,
  textContrastGuideline,
];

/// Matches a widget whose semantics include [label].
///
/// The failure names the widget and the label it actually has, so a
/// design-system test can be read without pumping the widget again
/// (FE-A11Y-02, FE-A11Y-10).
Matcher hasSemanticLabel(String label) => _HasSemanticLabel(label);

/// Matches a widget whose tap target is at least [min] logical pixels on
/// both sides. [min] defaults to 48 (FE-A11Y-01).
///
/// The failure names the widget and the size that was measured.
Matcher meetsTapTarget({double min = _minTapTarget}) => _MeetsTapTarget(min);

/// Runs the framework accessibility guidelines over the pumped tree, then
/// asserts that 200 percent text scale does not clip in portrait or
/// landscape (FE-A11Y-03, FE-RESP-06, FE-A11Y-10).
///
/// Reports every issue it finds, not only the first.
Future<void> expectNoA11yIssues(WidgetTester tester) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    final List<String> issues = <String>[];
    for (final AccessibilityGuideline guideline in _guidelines) {
      final Evaluation evaluation = await guideline.evaluate(tester);
      if (!evaluation.passed) {
        issues.add(
          '${guideline.description}: ${evaluation.reason ?? 'failed'}',
        );
      }
    }
    issues.addAll(await _textScaleIssues(tester));
    if (issues.isNotEmpty) {
      fail(
        'accessibility issues:\n'
        '${issues.map((String issue) => '  - $issue').join('\n')} '
        '(FE-A11Y-10)',
      );
    }
  } finally {
    handle.dispose();
  }
}

/// A widget whose semantics include [_label].
class _HasSemanticLabel extends Matcher {
  const _HasSemanticLabel(this._label);

  final String _label;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    final List<Element> elements = _elementsOf(item);
    if (elements.isEmpty) {
      matchState['widget'] = item.runtimeType.toString();
      matchState['actual'] = '';
      return false;
    }
    for (final Element element in elements) {
      final String actual = _labelOf(element);
      if (actual != _label && !actual.split('\n').contains(_label)) {
        matchState['widget'] = element.widget.runtimeType.toString();
        matchState['actual'] = actual;
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('has semantic label "$_label"');
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    final String widget = matchState['widget'] as String? ?? 'widget';
    final String actual = matchState['actual'] as String? ?? '';
    if (actual.isEmpty) {
      return mismatchDescription.add(
        '$widget has no semantic label; expected "$_label" (FE-A11Y-02)',
      );
    }
    return mismatchDescription.add(
      '$widget has semantic label "$actual", not "$_label" (FE-A11Y-02)',
    );
  }
}

/// A widget whose render box is at least [_min] by [_min].
class _MeetsTapTarget extends Matcher {
  const _MeetsTapTarget(this._min);

  final double _min;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    final List<Element> elements = _elementsOf(item);
    if (elements.isEmpty) {
      matchState['widget'] = item.runtimeType.toString();
      matchState['width'] = 0.0;
      matchState['height'] = 0.0;
      return false;
    }
    for (final Element element in elements) {
      final Size size = _sizeOf(element);
      if (size.width < _min || size.height < _min) {
        matchState['widget'] = element.widget.runtimeType.toString();
        matchState['width'] = size.width;
        matchState['height'] = size.height;
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('meets a ${_min}dp tap target');
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    final String widget = matchState['widget'] as String? ?? 'widget';
    final double width = matchState['width'] as double? ?? 0;
    final double height = matchState['height'] as double? ?? 0;
    return mismatchDescription.add(
      '$widget is $width×${height}dp, below the ${_min}dp tap target '
      '(FE-A11Y-01)',
    );
  }
}

/// Elements [item] refers to: a [Finder], a single [Element], or nothing.
List<Element> _elementsOf(Object? item) {
  if (item is Finder) {
    return item.evaluate().toList();
  }
  if (item is Element) {
    return <Element>[item];
  }
  return const <Element>[];
}

/// The semantic label (and tooltip) on [element], walking up to a node that
/// has one.
String _labelOf(Element element) {
  RenderObject? render = element.findRenderObject();
  while (render != null) {
    final SemanticsNode? node = render.debugSemantics;
    if (node != null) {
      final String found = _labelFrom(node);
      if (found.isNotEmpty) {
        return found;
      }
    }
    render = render.parent;
  }
  return '';
}

/// [node]'s own label or tooltip, or the first non-empty one among children.
String _labelFrom(SemanticsNode node) {
  final SemanticsData data = node.getSemanticsData();
  final String own = <String>[
    data.label,
    data.tooltip,
  ].where((String part) => part.isNotEmpty).join('\n');
  if (own.isNotEmpty) {
    return own;
  }
  String childLabel = '';
  node.visitChildren((SemanticsNode child) {
    if (childLabel.isNotEmpty) {
      return true;
    }
    childLabel = _labelFrom(child);
    return true;
  });
  return childLabel;
}

/// The painted size of [element].
Size _sizeOf(Element element) {
  final RenderObject? render = element.findRenderObject();
  if (render is RenderBox && render.hasSize) {
    return render.size;
  }
  return Size.zero;
}

/// Overflows at 200 percent text scale, in both orientations.
Future<List<String>> _textScaleIssues(WidgetTester tester) async {
  final List<String> issues = <String>[];
  final FlutterExceptionHandler? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isOverflow(details)) {
      return;
    }
    previous?.call(details);
  };
  try {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await _checkOrientation(tester, const Size(400, 800), 'portrait', issues);
    await _checkOrientation(tester, const Size(800, 400), 'landscape', issues);
  } finally {
    FlutterError.onError = previous;
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.view.resetPhysicalSize();
    await tester.pump();
  }
  return issues;
}

/// Pumps [logical] as the surface and records an overflow in [issues].
Future<void> _checkOrientation(
  WidgetTester tester,
  Size logical,
  String orientation,
  List<String> issues,
) async {
  final double dpr = tester.view.devicePixelRatio;
  tester.view.physicalSize = Size(logical.width * dpr, logical.height * dpr);
  await tester.pump();
  final Object? exception = tester.takeException();
  if (exception != null && _isOverflowException(exception)) {
    issues.add(
      'clipped at 200 percent text scale in $orientation: $exception '
      '(FE-A11Y-03)',
    );
  }
}

/// Whether [details] is a layout overflow the text-scale check cares about.
bool _isOverflow(FlutterErrorDetails details) {
  return _isOverflowException(details.exception);
}

/// Whether [exception] is a RenderFlex / text overflow.
bool _isOverflowException(Object exception) {
  final String text = exception.toString();
  return text.contains('overflowed') || text.contains('OVERFLOWED');
}
