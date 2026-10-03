import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';

/// Splits a recording into chunks and folds a run into a new version.
///
/// A failed chunk drops only itself. Versions already stored stay as they
/// were.
final class MeetingTranscription {
  /// How many chunks [byteLength] becomes. Zero bytes is no chunk.
  static int chunkCount(int byteLength, {int? chunkBytes}) {
    final int size = chunkBytes ?? AppConstants.meetings.transcriptChunkBytes;
    if (byteLength <= 0 || size <= 0) {
      return 0;
    }
    return (byteLength + size - 1) ~/ size;
  }

  /// [recording] as playable clips of about [chunkBytes] of sound each, in
  /// order. A PCM WAV is cut on whole frames, each clip with its own
  /// header, so an interrupted file whose header was never finished is read
  /// to its last byte. Anything else is one clip, as it is.
  static List<Uint8List> split(Uint8List recording, {int? chunkBytes}) {
    final _Wav? wav = _Wav.parse(recording);
    if (wav == null) {
      return recording.isEmpty ? const <Uint8List>[] : <Uint8List>[recording];
    }
    final int frame = wav.blockAlign <= 0 ? 1 : wav.blockAlign;
    final int wanted = chunkBytes ?? AppConstants.meetings.transcriptChunkBytes;
    final int size = wanted < frame ? frame : wanted - (wanted % frame);
    final int count = chunkCount(wav.dataLength, chunkBytes: size);
    return <Uint8List>[
      for (int index = 0; index < count; index++)
        wav.clip(
          index * size,
          (index + 1) * size > wav.dataLength
              ? wav.dataLength
              : (index + 1) * size,
        ),
    ];
  }

  /// Adds one version built from [chunks]. [existing] is returned unchanged
  /// ahead of that version.
  static List<TranscriptVersion> fold({
    required List<TranscriptVersion> existing,
    required List<TranscriptChunk> chunks,
  }) {
    final StringBuffer text = StringBuffer();
    final List<int> failed = <int>[];
    for (final TranscriptChunk chunk in chunks) {
      if (chunk.failed) {
        failed.add(chunk.index);
        continue;
      }
      if (text.isNotEmpty && chunk.text.isNotEmpty) {
        text.write('\n');
      }
      text.write(chunk.text);
    }
    return <TranscriptVersion>[
      ...existing,
      (
        version: existing.length + 1,
        text: text.toString(),
        failedChunks: List<int>.unmodifiable(failed),
      ),
    ];
  }

  /// [versions] as the JSON the meeting document keeps.
  static List<Map<String, Object?>> toJson(List<TranscriptVersion> versions) {
    return <Map<String, Object?>>[
      for (final TranscriptVersion version in versions)
        <String, Object?>{
          'version': version.version,
          'text': version.text,
          'failedChunks': version.failedChunks,
        },
    ];
  }

  /// Versions written by [toJson]. Anything unreadable is skipped.
  static List<TranscriptVersion> fromJson(Object? raw) {
    if (raw is! List<Object?>) {
      return const <TranscriptVersion>[];
    }
    return <TranscriptVersion>[
      for (final Object? entry in raw)
        if (entry is Map && entry['version'] is int)
          (
            version: entry['version'] as int,
            text: entry['text'] as String? ?? '',
            failedChunks: List<int>.unmodifiable(<int>[
              for (final Object? index
                  in entry['failedChunks'] as List<Object?>? ??
                      const <Object?>[])
                if (index is int) index,
            ]),
          ),
    ];
  }
}

/// One chunk of a long recording after transcription was attempted.
typedef TranscriptChunk = ({int index, String text, bool failed});

/// One stored run. A later run is another version; none is replaced.
typedef TranscriptVersion = ({
  int version,
  String text,
  List<int> failedChunks,
});

/// The sound of a PCM WAV and the format header its clips repeat.
final class _Wav {
  const _Wav(this._bytes, this._format, this._dataStart, this.dataLength);

  /// The WAV in [bytes], or null when it is not a RIFF WAVE with a format
  /// and a data chunk.
  static _Wav? parse(Uint8List bytes) {
    if (bytes.length < _riffHeader + _chunkHeader ||
        String.fromCharCodes(bytes, 0, 4) != 'RIFF' ||
        String.fromCharCodes(bytes, 8, 12) != 'WAVE') {
      return null;
    }
    final ByteData view = ByteData.sublistView(bytes);
    Uint8List? format;
    int offset = _riffHeader;
    while (offset + _chunkHeader <= bytes.length) {
      final String id = String.fromCharCodes(bytes, offset, offset + 4);
      final int size = view.getUint32(offset + 4, Endian.little);
      final int body = offset + _chunkHeader;
      if (id == 'fmt ' && body + _pcmFormat <= bytes.length) {
        format = Uint8List.sublistView(bytes, body, body + _pcmFormat);
      }
      if (id == 'data') {
        if (format == null) {
          return null;
        }
        final int available = bytes.length - body;
        final int length = size == 0 || size > available ? available : size;
        return _Wav(bytes, format, body, length);
      }
      offset = body + size + (size.isOdd ? 1 : 0);
    }
    return null;
  }

  final Uint8List _bytes;
  final Uint8List _format;
  final int _dataStart;

  /// Bytes of sound after the header.
  final int dataLength;

  /// Bytes per frame, from the format header.
  int get blockAlign =>
      ByteData.sublistView(_format).getUint16(12, Endian.little);

  /// Sound bytes [from] to [to] as a WAV of their own.
  Uint8List clip(int from, int to) {
    final int length = to - from;
    final Uint8List out = Uint8List(_canonicalHeader + length);
    final ByteData view = ByteData.sublistView(out);
    out.setAll(0, 'RIFF'.codeUnits);
    view.setUint32(4, _canonicalHeader - _chunkHeader + length, Endian.little);
    out.setAll(8, 'WAVEfmt '.codeUnits);
    view.setUint32(16, _pcmFormat, Endian.little);
    out.setAll(20, _format);
    out.setAll(36, 'data'.codeUnits);
    view.setUint32(40, length, Endian.little);
    out.setRange(_canonicalHeader, out.length, _bytes, _dataStart + from);
    return out;
  }
}

/// `RIFF`, the size and `WAVE`.
const int _riffHeader = 12;

/// A chunk's id and size.
const int _chunkHeader = 8;

/// The PCM fields of a `fmt ` chunk.
const int _pcmFormat = 16;

/// RIFF, format and data headers of a canonical PCM WAV.
const int _canonicalHeader = 44;
