/// Web stand-in. File ranges are read on devices that have a filesystem.
Future<List<int>> readCloudFileRange(
  String path,
  int offset,
  int length,
) async {
  if (path.isEmpty || offset < 0 || length < 0) {
    return const <int>[];
  }
  return const <int>[];
}
