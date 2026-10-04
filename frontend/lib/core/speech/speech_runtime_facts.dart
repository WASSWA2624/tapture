import 'speech_cpu_feature.dart';
import 'speech_unavailable_reason.dart';

/// What the speech engine runtime reports about this device, read without
/// loading a model or starting a worker. Model selection decides from it.
final class SpeechRuntimeFacts {
  /// Describes the runtime. Unknown memory figures are null.
  const SpeechRuntimeFacts({
    required this.available,
    required this.is64Bit,
    required this.logicalCores,
    this.unavailableReason,
    this.engineVersion,
    this.abiVersion,
    this.cpuFeatures = const <SpeechCpuFeature>{},
    this.totalMemoryBytes,
    this.availableMemoryBytes,
    this.processLimitBytes,
    this.performanceCores,
    this.webThreads = false,
    this.webSimd = false,
  });

  /// Whether the engine can transcribe here at all.
  final bool available;

  /// Why it cannot, when [available] is false.
  final SpeechUnavailableReason? unavailableReason;

  /// The whisper.cpp version the library was built from.
  final String? engineVersion;

  /// The C ABI version the library speaks.
  final int? abiVersion;

  /// Processor features the library can use.
  final Set<SpeechCpuFeature> cpuFeatures;

  /// Whether the process runs 64-bit code.
  final bool is64Bit;

  /// Physical memory, in bytes.
  final int? totalMemoryBytes;

  /// Memory free for this process now, in bytes.
  final int? availableMemoryBytes;

  /// A per-process memory cap the platform enforces, in bytes.
  final int? processLimitBytes;

  /// Logical processors; 0 when the runtime reported nothing.
  final int logicalCores;

  /// Performance cores on a hybrid processor.
  final int? performanceCores;

  /// Whether the browser allows WebAssembly threads (cross-origin isolated).
  final bool webThreads;

  /// Whether the browser runs WebAssembly SIMD.
  final bool webSimd;
}
