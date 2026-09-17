import 'dart:io';

import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/logger.dart';

/// Writes the current logger's buffer to a shareable file in [into].
///
/// The file name carries the UTC date and the device id so support can tell
/// two exports apart without a server (FE-SEC-10).
Future<Result<File>> exportLog({required Directory into}) {
  return Result.captureAsync(() async {
    if (!into.existsSync()) {
      into.createSync(recursive: true);
    }
    final Logger logger = Logger.current;
    final File file = File('${into.path}/${logger.exportFileName}');
    await file.writeAsString(logger.buffer.join('\n'));
    return file;
  });
}
