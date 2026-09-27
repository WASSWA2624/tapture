import 'xlsx_sheet.dart';

/// One sheet per template, with unique valid tab names (task 018).
final class XlsxMultiSheet {
  /// Plans a sheet for each template. Names are unique and valid.
  static List<SheetPlan> plan(List<({String id, String name})> templates) {
    final Set<String> used = <String>{};
    return <SheetPlan>[
      for (final ({String id, String name}) template in templates)
        (
          templateId: template.id,
          sheetName: _unique(template.name, used),
          columns: const <String>[],
        ),
    ];
  }

  static String _unique(String name, Set<String> used) {
    var base = name.replaceAll(RegExp(r'[\[\]:*?/\\]'), '').trim();
    if (base.isEmpty) {
      base = 'Sheet';
    }
    if (base.length > XlsxSheet.maxNameLength) {
      base = base.substring(0, XlsxSheet.maxNameLength);
    }
    var candidate = base;
    var suffix = 2;
    while (used.contains(candidate) || !XlsxSheet.isValidName(candidate)) {
      final String tail = '-$suffix';
      final int room = XlsxSheet.maxNameLength - tail.length;
      candidate = '${base.substring(0, room.clamp(1, base.length))}$tail';
      suffix += 1;
    }
    used.add(candidate);
    return candidate;
  }
}

/// A template's sheet: id, tab name and column keys.
typedef SheetPlan = ({
  String templateId,
  String sheetName,
  List<String> columns,
});
