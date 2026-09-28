import 'package:tapture/core/errors/result.dart';

/// One problem a field tester flagged. It never leaves the device on its own.
final class FrictionLog {
  final List<
    ({
      String screen,
      DateTime at,
      String operatorName,
      String? projectId,
      String action,
      String? note,
      String? screenshotPath,
    })
  >
  _entries =
      <
        ({
          String screen,
          DateTime at,
          String operatorName,
          String? projectId,
          String action,
          String? note,
          String? screenshotPath,
        })
      >[];

  /// Records [screen] and the last [action]. [note] and a screenshot are optional.
  Future<Result<void>> logFriction({
    required String screen,
    required String action,
    required DateTime at,
    String operatorName = '',
    String? projectId,
    String? note,
    String? screenshotPath,
  }) async {
    _entries.add((
      screen: screen,
      at: at,
      operatorName: operatorName,
      projectId: projectId,
      action: action,
      note: note,
      screenshotPath: screenshotPath,
    ));
    return const Success<void>(null);
  }

  /// Every entry and screenshot path, as one text file the tester exports.
  String exportText() {
    final StringBuffer buffer = StringBuffer();
    for (final entry in _entries) {
      buffer.writeln(
        '${entry.at.toIso8601String()} ${entry.screen} ${entry.action} '
        '${entry.projectId ?? ''} ${entry.note ?? ''} ${entry.screenshotPath ?? ''}',
      );
    }
    return buffer.toString();
  }
}
