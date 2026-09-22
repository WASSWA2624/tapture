import 'package:tapture/core/constants/app_constants.dart';

/// Groups a record's photos into deterministic requests.
///
/// One record is one request until [cap]. A larger set splits on capture
/// order, so the same record always splits the same way.
final class RequestBatching {
  /// Splits [paths] in the order given. [cap] defaults to the app constant.
  static List<List<String>> split(List<String> paths, {int? cap}) {
    final int limit = cap ?? AppConstants.processing.extractionImageCap;
    if (paths.isEmpty) {
      return const <List<String>>[];
    }
    final int size = limit < 1 ? 1 : limit;
    final List<List<String>> batches = <List<String>>[];
    for (var start = 0; start < paths.length; start += size) {
      final int end = start + size > paths.length ? paths.length : start + size;
      batches.add(paths.sublist(start, end));
    }
    return batches;
  }
}
