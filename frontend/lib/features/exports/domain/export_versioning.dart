/// Allocates a dated, versioned folder for one export (task 018 step 15).
///
/// `v1`, `v2` and so on sit under the day's date inside a project's export
/// folder, so a repeated export never overwrites an earlier one. The writer
/// seeds [taken] with the folders its recorded exports already occupy.
final class ExportVersioning {
  /// Creates an allocator over the [taken] folders, as [allocate] returns
  /// them.
  ExportVersioning(this.taken);

  /// Folders already allocated, `<root>/yyyy-mm-dd/vN`.
  final Set<String> taken;

  /// The next free folder under [root], the project's export folder, for
  /// the UTC day of [now]. Never returns one already in [taken].
  Future<String> allocate(String root, DateTime now) async {
    final DateTime utc = now.toUtc();
    final String month = utc.month.toString().padLeft(2, '0');
    final String day = utc.day.toString().padLeft(2, '0');
    final String date = '${utc.year}-$month-$day';
    var version = 1;
    while (taken.contains('$root/$date/v$version')) {
      version += 1;
    }
    final String path = '$root/$date/v$version';
    taken.add(path);
    return path;
  }
}
