import 'dart:convert';

part 'pdf_name_boundaries.dart';

/// Checks a payload incrementally without retaining its complete contents.
/// PDF name boundaries affect only the heuristic view passed to the checker.
final class BundlePayloadScanner {
  /// Creates a scan with the canonical raw and heuristic text checker.
  BundlePayloadScanner(this._check);

  final void Function(String raw, String base64View) _check;
  final List<int> _prefix = <int>[];
  _PdfNameBoundaries? _pdf;
  bool _identified = false;
  bool _finished = false;
  String _rawOverlap = '';
  String _viewOverlap = '';

  /// Checks [bytes] in order, carrying lexical state and bounded overlap.
  void add(List<int> bytes) {
    if (_finished) throw StateError('The payload scan has finished.');
    if (bytes.isEmpty) return;
    if (!_identified) {
      final int needed = 5 - _prefix.length;
      _prefix.addAll(bytes.take(needed));
      if (_prefix.length < 5) return;
      _identified = true;
      if (ascii.decode(_prefix, allowInvalid: true) == '%PDF-') {
        _pdf = _PdfNameBoundaries();
      }
      _scan(_prefix);
      _prefix.clear();
      if (bytes.length > needed) _scan(bytes.sublist(needed));
      return;
    }
    _scan(bytes);
  }

  /// Checks a short trailing prefix and closes this scan.
  void finish() {
    if (_finished) throw StateError('The payload scan has finished.');
    if (_prefix.isNotEmpty) _scan(_prefix);
    _prefix.clear();
    _finished = true;
  }

  void _scan(List<int> bytes) {
    final String raw = latin1.decode(bytes);
    final String view = _pdf?.transform(raw) ?? raw;
    final String checkedRaw = '$_rawOverlap$raw';
    final String checkedView = '$_viewOverlap$view';
    _check(checkedRaw, checkedView);
    _rawOverlap = _tail(checkedRaw);
    _viewOverlap = _tail(checkedView);
  }

  static String _tail(String text) =>
      text.substring((text.length - 256).clamp(0, text.length));
}
