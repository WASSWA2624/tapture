part of 'ocr_service.dart';

// The desktop and test reader. It knows one dot-matrix face, the 5x7 glyphs
// below, and reads dark text on a light plate: lines by row, glyphs by
// column, words by the wider gaps between glyphs.

/// Glyph grid the face is drawn on.
const int _glyphRows = 7;
const int _glyphColumns = 5;

/// Luma below which a pixel is ink.
const int _darkLuma = 160;

/// Most cells a glyph may differ from the face and still be read.
const int _maxCellMismatch = 8;

/// A line band shorter than the tallest band divided by this is noise.
const int _bandNoiseDivisor = 3;

/// A gap wider than the line height divided by this starts a new word.
const int _wordGapDivisor = 2;

Map<String, Object?> _read(img.Image source) {
  final List<String> lines = <String>[];
  final List<Object?> blocks = <Object?>[];
  for (final ({int top, int bottom}) band in _bands(source)) {
    final List<String> words = <String>[];
    for (final List<_Glyph> word in _words(source, band)) {
      final StringBuffer text = StringBuffer();
      var confidence = 0.0;
      var read = 0;
      var left = word.first.right;
      var right = word.first.left;
      for (final _Glyph glyph in word) {
        final ({String char, double confidence}) match = _match(glyph.rows);
        if (match.char.isEmpty) {
          continue;
        }
        text.write(match.char);
        confidence += match.confidence;
        read++;
        left = glyph.left < left ? glyph.left : left;
        right = glyph.right > right ? glyph.right : right;
      }
      if (read == 0) {
        continue;
      }
      words.add(text.toString());
      blocks.add(<Object?>[
        text.toString(),
        left,
        band.top,
        right + 1,
        band.bottom + 1,
        confidence / read,
      ]);
    }
    if (words.isNotEmpty) {
      lines.add(words.join(' '));
    }
  }
  return <String, Object?>{'text': lines.join('\n'), 'blocks': blocks};
}

class _Glyph {
  _Glyph({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.rows,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;
  final List<String> rows;
}

/// Horizontal bands of rows holding ink, top to bottom, noise dropped.
List<({int top, int bottom})> _bands(img.Image source) {
  final List<({int top, int bottom})> bands = <({int top, int bottom})>[];
  int? start;
  for (var y = 0; y <= source.height; y++) {
    final bool ink = y < source.height && _rowHasInk(source, y);
    if (ink && start == null) {
      start = y;
    } else if (!ink && start != null) {
      bands.add((top: start, bottom: y - 1));
      start = null;
    }
  }
  final int tallest = bands.fold<int>(
    0,
    (int most, ({int top, int bottom}) band) =>
        band.bottom - band.top + 1 > most ? band.bottom - band.top + 1 : most,
  );
  return <({int top, int bottom})>[
    for (final ({int top, int bottom}) band in bands)
      if ((band.bottom - band.top + 1) * _bandNoiseDivisor >= tallest) band,
  ];
}

bool _rowHasInk(img.Image source, int y) {
  for (var x = 0; x < source.width; x++) {
    if (_dark(source.getPixel(x, y))) {
      return true;
    }
  }
  return false;
}

/// The glyphs of one band, grouped into words by the gaps between them.
List<List<_Glyph>> _words(img.Image source, ({int top, int bottom}) band) {
  final List<bool> columnInk = List<bool>.filled(source.width, false);
  for (var y = band.top; y <= band.bottom; y++) {
    for (var x = 0; x < source.width; x++) {
      if (!columnInk[x] && _dark(source.getPixel(x, y))) {
        columnInk[x] = true;
      }
    }
  }
  final int wordGap = (band.bottom - band.top + 1) ~/ _wordGapDivisor;
  final List<List<_Glyph>> words = <List<_Glyph>>[];
  var x = 0;
  while (x < source.width) {
    while (x < source.width && !columnInk[x]) {
      x++;
    }
    if (x >= source.width) {
      break;
    }
    final int start = x;
    while (x < source.width && columnInk[x]) {
      x++;
    }
    final _Glyph glyph = _sample(source, start, x - 1, band.top, band.bottom);
    if (words.isEmpty || start - words.last.last.right - 1 > wordGap) {
      words.add(<_Glyph>[glyph]);
    } else {
      words.last.add(glyph);
    }
  }
  return words;
}

_Glyph _sample(img.Image source, int left, int right, int top, int bottom) {
  final List<String> rows = <String>[];
  final int glyphWidth = right - left + 1;
  final int glyphHeight = bottom - top + 1;
  for (var row = 0; row < _glyphRows; row++) {
    final StringBuffer bits = StringBuffer();
    final int y0 = top + (row * glyphHeight) ~/ _glyphRows;
    final int y1 = top + ((row + 1) * glyphHeight) ~/ _glyphRows;
    final int yEnd = y1 <= y0 ? y0 + 1 : y1;
    for (var col = 0; col < _glyphColumns; col++) {
      final int x0 = left + (col * glyphWidth) ~/ _glyphColumns;
      final int x1 = left + ((col + 1) * glyphWidth) ~/ _glyphColumns;
      final int xEnd = x1 <= x0 ? x0 + 1 : x1;
      var ink = 0;
      var seen = 0;
      for (var y = y0; y < yEnd && y <= bottom; y++) {
        for (var x = x0; x < xEnd && x <= right; x++) {
          seen++;
          if (_dark(source.getPixel(x, y))) {
            ink++;
          }
        }
      }
      bits.write(seen > 0 && ink * 2 >= seen ? '1' : '0');
    }
    rows.add(bits.toString());
  }
  return _Glyph(left: left, top: top, right: right, bottom: bottom, rows: rows);
}

({String char, double confidence}) _match(List<String> rows) {
  const int cells = _glyphRows * _glyphColumns;
  var best = '';
  var bestDistance = cells + 1;
  for (final MapEntry<String, List<String>> entry in _font.entries) {
    var distance = 0;
    for (var i = 0; i < _glyphRows; i++) {
      for (var bit = 0; bit < _glyphColumns; bit++) {
        if (rows[i][bit] != entry.value[i][bit]) {
          distance++;
        }
      }
    }
    if (distance < bestDistance) {
      bestDistance = distance;
      best = entry.key;
    }
  }
  if (bestDistance > _maxCellMismatch) {
    return (char: '', confidence: 0);
  }
  return (char: best, confidence: 1 - (bestDistance / cells));
}

bool _dark(img.Pixel pixel) => img.getLuminance(pixel) < _darkLuma;

/// Paints [text] in the reader's face as a dark-on-light plate, one line per
/// line break, so a test can hand the on-device reader an image with known
/// text without a checked-in fixture file.
@visibleForTesting
Uint8List paintOcrPlate(String text) {
  const int scale = 8;
  const int gap = 8;
  const int glyphWidth = _glyphColumns * scale + gap;
  const int lineHeight = _glyphRows * scale + gap * 2;
  final List<String> lines = text.split('\n');
  var widest = 1;
  for (final String line in lines) {
    if (line.length > widest) {
      widest = line.length;
    }
  }
  final img.Image plate = img.Image(
    width: widest * glyphWidth + gap,
    height: lines.length * lineHeight + gap,
  );
  img.fill(plate, color: img.ColorRgb8(255, 255, 255));
  for (int index = 0; index < lines.length; index++) {
    final int top = gap + index * lineHeight;
    var cursor = gap;
    for (final int rune in lines[index].runes) {
      final List<String>? rows = _font[String.fromCharCode(rune)];
      if (rows != null) {
        for (var row = 0; row < _glyphRows; row++) {
          for (var col = 0; col < _glyphColumns; col++) {
            if (rows[row][col] != '1') {
              continue;
            }
            img.fillRect(
              plate,
              x1: cursor + col * scale,
              y1: top + row * scale,
              x2: cursor + (col + 1) * scale - 1,
              y2: top + (row + 1) * scale - 1,
              color: img.ColorRgb8(0, 0, 0),
            );
          }
        }
      }
      cursor += glyphWidth;
    }
  }
  return Uint8List.fromList(img.encodePng(plate));
}

const Map<String, List<String>> _font = <String, List<String>>{
  // A slashed zero, so it never reads as the letter O.
  '0': <String>['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
  '1': <String>['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
  '2': <String>['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
  '3': <String>['01110', '10001', '00001', '00110', '00001', '10001', '01110'],
  '4': <String>['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
  '5': <String>['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
  '6': <String>['01110', '10000', '11110', '10001', '10001', '10001', '01110'],
  '7': <String>['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
  '8': <String>['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
  '9': <String>['01110', '10001', '10001', '01111', '00001', '00001', '01110'],
  'A': <String>['01110', '10001', '10001', '11111', '10001', '10001', '10001'],
  'B': <String>['11110', '10001', '10001', '11110', '10001', '10001', '11110'],
  'C': <String>['01110', '10001', '10000', '10000', '10000', '10001', '01110'],
  'D': <String>['11110', '10001', '10001', '10001', '10001', '10001', '11110'],
  'E': <String>['11111', '10000', '10000', '11110', '10000', '10000', '11111'],
  'F': <String>['11111', '10000', '10000', '11110', '10000', '10000', '10000'],
  'G': <String>['01110', '10001', '10000', '10111', '10001', '10001', '01110'],
  'H': <String>['10001', '10001', '10001', '11111', '10001', '10001', '10001'],
  'I': <String>['01110', '00100', '00100', '00100', '00100', '00100', '01110'],
  'J': <String>['00111', '00010', '00010', '00010', '10010', '10010', '01100'],
  'K': <String>['10001', '10010', '10100', '11000', '10100', '10010', '10001'],
  'L': <String>['10000', '10000', '10000', '10000', '10000', '10000', '11111'],
  'M': <String>['10001', '11011', '10101', '10101', '10001', '10001', '10001'],
  'N': <String>['10001', '11001', '10101', '10011', '10001', '10001', '10001'],
  'O': <String>['01110', '10001', '10001', '10001', '10001', '10001', '01110'],
  'P': <String>['11110', '10001', '10001', '11110', '10000', '10000', '10000'],
  'Q': <String>['01110', '10001', '10001', '10001', '10101', '10010', '01101'],
  'R': <String>['11110', '10001', '10001', '11110', '10100', '10010', '10001'],
  'S': <String>['01111', '10000', '10000', '01110', '00001', '00001', '11110'],
  'T': <String>['11111', '00100', '00100', '00100', '00100', '00100', '00100'],
  'U': <String>['10001', '10001', '10001', '10001', '10001', '10001', '01110'],
  'V': <String>['10001', '10001', '10001', '10001', '10001', '01010', '00100'],
  'W': <String>['10001', '10001', '10001', '10101', '10101', '10101', '01010'],
  'X': <String>['10001', '10001', '01010', '00100', '01010', '10001', '10001'],
  'Y': <String>['10001', '10001', '01010', '00100', '00100', '00100', '00100'],
  'Z': <String>['11111', '00001', '00010', '00100', '01000', '10000', '11111'],
  '-': <String>['00000', '00000', '00000', '11111', '00000', '00000', '00000'],
};
