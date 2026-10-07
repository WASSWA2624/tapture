part of 'bundle_payload_scanner.dart';

/// Separates PDF dictionary names only in syntax, leaving data untouched.
/// Direct stream lengths avoid interpreting binary bytes as PDF syntax. An
/// uncertain or malformed stream switches permanently to the strict raw view.
final class _PdfNameBoundaries {
  final List<_PdfDictionary> _dictionaries = <_PdfDictionary>[];
  _PdfMode _mode = _PdfMode.syntax;
  String _token = '';
  bool _tokenOverflow = false;
  int _angle = 0;
  int _literalDepth = 0;
  bool _escaped = false;
  int? _lastLength;
  int _remaining = 0;
  bool _skipLf = false;
  int _endIndex = 0;

  String transform(String text) {
    final StringBuffer output = StringBuffer();
    int copied = 0;
    bool changed = false;
    for (int index = 0; index < text.length; index++) {
      final int byte = text.codeUnitAt(index);
      if (_mode == _PdfMode.syntax && _angle == 0 && byte == 47) {
        _flushToken();
        if (_mode == _PdfMode.syntax && _dictionaries.isNotEmpty) {
          output.write(text.substring(copied, index));
          output.write(' ');
          copied = index;
          changed = true;
        }
      }
      _consume(byte);
    }
    if (!changed) return text;
    output.write(text.substring(copied));
    return output.toString();
  }

  void _consume(int byte) {
    switch (_mode) {
      case _PdfMode.opaque:
        return;
      case _PdfMode.comment:
        if (byte == 10 || byte == 13) _mode = _PdfMode.syntax;
        return;
      case _PdfMode.literal:
        if (_escaped) {
          _escaped = false;
        } else if (byte == 92) {
          _escaped = true;
        } else if (byte == 40) {
          _literalDepth++;
        } else if (byte == 41 && --_literalDepth == 0) {
          _mode = _PdfMode.syntax;
        }
        return;
      case _PdfMode.hex:
        if (byte == 62) _mode = _PdfMode.syntax;
        return;
      case _PdfMode.stream:
        if (_skipLf) {
          _skipLf = false;
          if (byte == 10) return;
        }
        if (_remaining > 0) {
          _remaining--;
          return;
        }
        _mode = _PdfMode.streamEnd;
        _consume(byte);
        return;
      case _PdfMode.streamEnd:
        const String marker = 'endstream';
        if (_endIndex == 0 && _white(byte)) return;
        if (_endIndex < marker.length && byte == marker.codeUnitAt(_endIndex)) {
          _endIndex++;
        } else if (_endIndex == marker.length && _white(byte)) {
          _mode = _PdfMode.syntax;
          _lastLength = null;
        } else {
          _mode = _PdfMode.opaque;
        }
        return;
      case _PdfMode.syntax:
        _syntax(byte);
    }
  }

  void _syntax(int byte) {
    if (_angle != 0) {
      final int previous = _angle;
      _angle = 0;
      if (byte == previous) {
        if (byte == 60) {
          if (_dictionaries.length == 32) {
            _mode = _PdfMode.opaque;
          } else {
            _dictionaries.add(_PdfDictionary());
          }
        } else if (_dictionaries.isNotEmpty) {
          _lastLength = _dictionaries.removeLast().length;
        }
        return;
      }
      if (previous == 60) {
        _mode = _PdfMode.hex;
        _consume(byte);
        return;
      }
    }
    if (_white(byte) || _delimiter(byte)) {
      _flushToken();
      if (_mode != _PdfMode.syntax) {
        if (_mode == _PdfMode.stream) {
          if (byte != 10 && byte != 13) {
            _mode = _PdfMode.opaque;
          } else {
            _skipLf = byte == 13;
          }
        }
        return;
      }
      switch (byte) {
        case 37:
          _mode = _PdfMode.comment;
        case 40:
          _markValue();
          _literalDepth = 1;
          _mode = _PdfMode.literal;
        case 60:
        case 62:
          _markValue();
          _angle = byte;
        case 47:
          _token = '/';
        case 91:
        case 93:
          _markValue();
      }
      return;
    }
    if (_token.length < 32) {
      _token += String.fromCharCode(byte);
    } else {
      _tokenOverflow = true;
    }
  }

  void _flushToken() {
    if (_token.isEmpty) return;
    if (!_tokenOverflow && _token == 'stream' && _dictionaries.isEmpty) {
      final int? length = _lastLength;
      if (length == null) {
        _mode = _PdfMode.opaque;
      } else {
        _remaining = length;
        _endIndex = 0;
        _mode = _PdfMode.stream;
      }
    } else if (_dictionaries.isNotEmpty) {
      _dictionaries.last.token(_tokenOverflow ? '' : _token);
    } else {
      _lastLength = null;
    }
    _token = '';
    _tokenOverflow = false;
  }

  void _markValue() {
    if (_dictionaries.isNotEmpty) _dictionaries.last.token('');
  }

  static bool _white(int byte) =>
      byte == 0 ||
      byte == 9 ||
      byte == 10 ||
      byte == 12 ||
      byte == 13 ||
      byte == 32;

  static bool _delimiter(int byte) =>
      byte == 37 ||
      byte == 40 ||
      byte == 41 ||
      byte == 47 ||
      byte == 60 ||
      byte == 62 ||
      byte == 91 ||
      byte == 93 ||
      byte == 123 ||
      byte == 125;
}

final class _PdfDictionary {
  int? length;
  bool _expectsLength = false;
  bool _lengthCandidate = false;

  void token(String text) {
    if (text == '/Length') {
      length = null;
      _expectsLength = true;
      _lengthCandidate = false;
    } else if (_expectsLength) {
      final int? value = int.tryParse(text);
      length = value != null && value >= 0 ? value : null;
      _expectsLength = false;
      _lengthCandidate = true;
    } else if (_lengthCandidate) {
      // `/Length n 0 R` is an indirect object reference, not a byte count.
      if (int.tryParse(text) != null || text == 'R') length = null;
      _lengthCandidate = false;
    }
  }
}

enum _PdfMode { syntax, comment, literal, hex, stream, streamEnd, opaque }
