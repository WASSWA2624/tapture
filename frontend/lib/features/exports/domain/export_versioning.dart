/// Allocates a dated, versioned folder for one export (task 018).
///
/// `v1`, `v2` and so on sit under the day's date. A later export never
/// reuses a folder that already exists.
final class ExportVersioning {
  /// Creates an allocator over the [taken] paths already on disk.
  ExportVersioning(this.taken);

  /// Paths already allocated, `project/yyyy-mm-dd/vN`.
  final Set<String> taken;

  /// The next free directory for [projectId] on [now].
  Future<String> allocate(String projectId, DateTime now) async {
    final DateTime utc = now.toUtc();
    final String month = utc.month.toString().padLeft(2, '0');
    final String day = utc.day.toString().padLeft(2, '0');
    final String date = '${utc.year}-$month-$day';
    var version = 1;
    while (taken.contains('$projectId/$date/v$version')) {
      version += 1;
    }
    final String path = '$projectId/$date/v$version';
    taken.add(path);
    return path;
  }
}
