/// Total, used and free bytes on the storage root's volume.
final class VolumeStats {
  /// Creates a volume snapshot. [totalBytes] is [usedBytes] plus [freeBytes]
  /// when the platform reports only those two.
  const VolumeStats({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
  });

  /// Capacity of the volume, in bytes.
  final int totalBytes;

  /// Occupied space, in bytes.
  final int usedBytes;

  /// Available space, in bytes.
  final int freeBytes;

  /// Reads 1024-blocks, used and available from `df -Pk` output.
  factory VolumeStats.parsePosixDf(String stdout) {
    final List<String> lines = stdout.trim().split(RegExp(r'\r?\n'));
    if (lines.length < 2) {
      throw const FormatException('df');
    }
    final List<String> parts = lines.last.trim().split(RegExp(r'\s+'));
    final int start = int.tryParse(parts.first) == null ? 1 : 0;
    if (parts.length < start + 3) {
      throw const FormatException('df');
    }
    final int? blocks = int.tryParse(parts[start]);
    final int? used = int.tryParse(parts[start + 1]);
    final int? available = int.tryParse(parts[start + 2]);
    if (blocks == null || used == null || available == null) {
      throw const FormatException('df');
    }
    return VolumeStats(
      totalBytes: blocks * 1024,
      usedBytes: used * 1024,
      freeBytes: available * 1024,
    );
  }

  /// Reads Used and Free from a `Get-PSDrive` line. Total is their sum.
  factory VolumeStats.parseWindowsPsDrive(String stdout) {
    final List<String> parts = stdout.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      throw const FormatException('psdrive');
    }
    final int? used = int.tryParse(parts[0]);
    final int? free = int.tryParse(parts[1]);
    if (used == null || free == null) {
      throw const FormatException('psdrive');
    }
    return VolumeStats(
      totalBytes: used + free,
      usedBytes: used,
      freeBytes: free,
    );
  }

  /// Reads the three figures a `volumeStats` channel reply carries.
  factory VolumeStats.fromChannel(Map<Object?, Object?> raw) {
    final int? total = _intOf(raw['totalBytes']);
    final int? used = _intOf(raw['usedBytes']);
    final int? free = _intOf(raw['freeBytes']);
    if (total == null || used == null || free == null) {
      throw const FormatException('volumeStats');
    }
    return VolumeStats(totalBytes: total, usedBytes: used, freeBytes: free);
  }
}

int? _intOf(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}
