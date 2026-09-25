/// Operator-facing workbook name. Pure so a test can pin the clock.
abstract final class ExportFileName {
  /// `PROJECT-NAME-DDMMYY-HHMMSS.xlsx` from [projectName] and [local].
  static String build({required String projectName, required DateTime local}) {
    final String stem = _stem(projectName);
    final String dd = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String yy = (local.year % 100).toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    final String second = local.second.toString().padLeft(2, '0');
    return '$stem-$dd$month$yy-$hour$minute$second.xlsx';
  }

  static String _stem(String projectName) {
    final String cleaned = projectName.replaceAll(
      RegExp(r'[^A-Za-z0-9]+'),
      '-',
    );
    final String collapsed = cleaned.replaceAll(RegExp(r'-{2,}'), '-');
    final String trimmed = collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
    return trimmed.isEmpty ? 'Project' : trimmed;
  }
}
