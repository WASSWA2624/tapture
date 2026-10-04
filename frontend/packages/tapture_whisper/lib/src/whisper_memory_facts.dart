/// The device's memory (`tw_memory_info`); a figure the platform does not
/// report is null.
final class WhisperMemoryFacts {
  /// Describes the device's memory.
  const WhisperMemoryFacts({
    this.totalBytes,
    this.availableBytes,
    this.processLimitBytes,
  });

  /// Physical memory, in bytes.
  final int? totalBytes;

  /// Memory a new allocation can have now, in bytes.
  final int? availableBytes;

  /// The per-process limit the platform enforces (iOS), in bytes.
  final int? processLimitBytes;
}
