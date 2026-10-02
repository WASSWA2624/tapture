import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

import 'geo_fix.dart';

export 'geo_fix.dart';

/// Pure location port for capture rules; platform permission stays in the adapter.
abstract interface class LocationReader {
  /// Returns an optional fix within [timeout], without blocking capture on denial.
  Future<Result<GeoFix?>> currentFix({
    Duration timeout = AppConstants.locationTimeout,
  });
}
