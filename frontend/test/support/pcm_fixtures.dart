import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:tapture/core/audio/memory_pcm_store.dart';
import 'package:tapture/core/speech/pipeline/pcm_conversion.dart';

import 'spoken_script.dart';

/// Synthetic and real 16 kHz mono PCM for speech pipeline tests
/// (FE-TEST-04).
///
/// A [SpokenScript] becomes audio by giving every word a burst of
/// band-limited noise at [wordDbfs] over a room tone at [roomDbfs]; the
/// fake speech engine's detector hears loudness, so its frames inside a
/// word read as speech. Levels are root-mean-square dBFS, the scale
/// `PcmConversion.rmsDbfs` measures.
abstract final class PcmFixtures {
  /// How loud a word is said close to the microphone.
  static const double wordDbfs = -20;

  /// A quiet room's tone.
  static const double roomDbfs = -70;

  /// A far voice that is still speech.
  static const double farVoiceDbfs = -50;

  /// whisper.cpp's `samples/jfk.wav` (MIT), vendored with the plugin: 11 s
  /// of 16 kHz mono speech. Silero v6.2.0 hears speech at 0.32–2.27,
  /// 3.27–4.41, 5.38–7.68 and 8.16–10.62 s in it.
  static const String jfkPath =
      'packages/tapture_whisper/third_party/whisper.cpp/samples/jfk.wav';

  /// [script] as audio of [length] samples (by default to the script's end
  /// plus one second): words at [word] dBFS over room tone at [room] dBFS,
  /// or digital silence between words when [room] is null.
  static Int16List fromScript(
    SpokenScript script, {
    int? length,
    double word = wordDbfs,
    double? room = roomDbfs,
    int seed = 1,
  }) {
    final Random random = Random(seed);
    final int total =
        length ?? script.endSample + SpokenScript.samplesOf(_tail);
    final Int16List samples = room == null
        ? Int16List(total)
        : noise(total, room, random: random);
    for (final SpokenWord spoken in script.words) {
      final int end = min(spoken.endSample, total);
      if (spoken.startSample >= end) {
        continue;
      }
      samples.setRange(
        spoken.startSample,
        end,
        noise(end - spoken.startSample, word, random: random),
      );
    }
    return samples;
  }

  /// [length] samples of band-limited noise at exactly [dbfs] RMS.
  static Int16List noise(int length, double dbfs, {Random? random}) {
    final Random source = random ?? Random(7);
    final Float64List shaped = Float64List(length);
    double previous = 0;
    double squares = 0;
    for (int index = 0; index < length; index++) {
      // A one-pole low-pass keeps the burst below about 4 kHz, like speech.
      previous = 0.6 * previous + 0.4 * (source.nextDouble() * 2 - 1);
      shaped[index] = previous;
      squares += previous * previous;
    }
    final Int16List samples = Int16List(length);
    if (length == 0 || squares == 0) {
      return samples;
    }
    final double target = 32768 * pow(10, dbfs / 20).toDouble();
    final double scale = target / sqrt(squares / length);
    for (int index = 0; index < length; index++) {
      samples[index] = (shaped[index] * scale).round().clamp(-32768, 32767);
    }
    return samples;
  }

  /// [samples] in a memory store, as a capture would have appended them.
  static MemoryPcmStore storeOf(Int16List samples, {int? maxSamples}) {
    final MemoryPcmStore store = MemoryPcmStore(
      maxSamples: maxSamples ?? max(samples.length, 1),
    );
    store.append(samples);
    return store;
  }

  /// The samples of the 16-bit mono WAV at [path], or null when it is
  /// absent.
  static Int16List? wavSamples(String path) {
    final File file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    final Uint8List wav = file.readAsBytesSync();
    final ByteData data = ByteData.sublistView(wav);
    int at = 12;
    while (at + 8 <= wav.length) {
      final String id = String.fromCharCodes(wav.sublist(at, at + 4));
      final int size = data.getUint32(at + 4, Endian.little);
      if (id == 'data') {
        final Int16List samples = Int16List(size ~/ 2);
        for (int index = 0; index < samples.length; index++) {
          samples[index] = data.getInt16(at + 8 + index * 2, Endian.little);
        }
        return samples;
      }
      at += 8 + size + (size & 1);
    }
    return null;
  }

  /// jfk.wav's samples, or null when the plugin's sources are absent.
  static Int16List? jfk() => wavSamples(jfkPath);

  /// The WAV at [path] as the speech engine reads it, floats in [-1, 1),
  /// or null when it is absent.
  static Float32List? wavFloats(String path) {
    final Int16List? samples = wavSamples(path);
    if (samples == null) {
      return null;
    }
    final Float32List floats = Float32List(samples.length);
    PcmConversion.toFloat32(samples, floats);
    return floats;
  }

  static const Duration _tail = Duration(seconds: 1);
}
