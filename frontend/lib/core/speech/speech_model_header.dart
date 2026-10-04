import 'dart:typed_data';

import 'speech_model_entry.dart';
import 'speech_model_kind.dart';

/// The first 48 bytes of a ggml whisper model: the magic and eleven
/// little-endian int32 hyperparameters, in file order.
///
/// A cheap precheck before hashing or loading: it catches a truncated,
/// foreign or mismatched file without reading the rest of it.
final class SpeechModelHeader {
  /// Holds already-parsed header fields; use [parse] to read a file's.
  const SpeechModelHeader({
    required this.magic,
    required this.nVocab,
    required this.nAudioCtx,
    required this.nAudioState,
    required this.nAudioHead,
    required this.nAudioLayer,
    required this.nTextCtx,
    required this.nTextState,
    required this.nTextHead,
    required this.nTextLayer,
    required this.nMels,
    required this.ftype,
  });

  /// The ggml magic, `0x67676d6c`, stored little-endian as `lmgg`.
  static const int ggmlMagic = 0x67676d6c;

  /// How many leading bytes [parse] needs.
  static const int length = 48;

  /// Reads the header from a file's first [length] bytes, or returns null
  /// when fewer are given. The magic is reported by [mismatchesWith], not
  /// here, so a caller can name what is wrong.
  static SpeechModelHeader? parse(Uint8List first48) {
    if (first48.length < length) {
      return null;
    }
    final ByteData view = ByteData.sublistView(first48, 0, length);
    int field(int index) => view.getInt32(4 + index * 4, Endian.little);
    return SpeechModelHeader(
      magic: view.getUint32(0, Endian.little),
      nVocab: field(0),
      nAudioCtx: field(1),
      nAudioState: field(2),
      nAudioHead: field(3),
      nAudioLayer: field(4),
      nTextCtx: field(5),
      nTextState: field(6),
      nTextHead: field(7),
      nTextLayer: field(8),
      nMels: field(9),
      ftype: field(10),
    );
  }

  /// The file magic; [ggmlMagic] for any ggml model.
  final int magic;

  /// Vocabulary size.
  final int nVocab;

  /// Audio context length in frames.
  final int nAudioCtx;

  /// Audio encoder state width.
  final int nAudioState;

  /// Audio encoder attention heads.
  final int nAudioHead;

  /// Audio encoder layers.
  final int nAudioLayer;

  /// Text context length in tokens.
  final int nTextCtx;

  /// Text decoder state width.
  final int nTextState;

  /// Text decoder attention heads.
  final int nTextHead;

  /// Text decoder layers.
  final int nTextLayer;

  /// Mel bands.
  final int nMels;

  /// Weight type plus the quantisation version times 1000.
  final int ftype;

  /// The names of the fields that disagree with [entry], empty when the
  /// header fits it. A VAD entry is checked by magic only; a whisper entry
  /// also by its hyperparameters, with [ftype] compared as `ftype % 1000`.
  List<String> mismatchesWith(SpeechModelEntry entry) {
    return <String>[
      if (magic != ggmlMagic) 'magic',
      if (entry.kind == SpeechModelKind.whisper) ...<String>[
        if (nVocab != entry.nVocab) 'nVocab',
        if (nAudioState != entry.nAudioState) 'nAudioState',
        if (nAudioLayer != entry.nAudioLayer) 'nAudioLayer',
        if (nTextLayer != entry.nTextLayer) 'nTextLayer',
        if (nMels != entry.nMels) 'nMels',
        if (ftype % 1000 != entry.ftype) 'ftype',
      ],
    ];
  }
}
