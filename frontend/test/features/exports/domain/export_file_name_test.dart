import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/exports/domain/export_file_name.dart';

void main() {
  final DateTime at = DateTime(2026, 9, 27, 8, 5, 9);

  test('a package is named after the project and the local time', () {
    expect(
      ExportFileName.build(
        projectName: 'Gulu pumps',
        local: at,
        extension: 'zip',
      ),
      'Gulu-pumps-270926-080509.zip',
    );
  });

  test('the workbook extension stays the default', () {
    expect(
      ExportFileName.build(projectName: 'Gulu pumps', local: at),
      'Gulu-pumps-270926-080509.xlsx',
    );
  });

  test('a name with nothing safe in it becomes Project', () {
    expect(
      ExportFileName.build(projectName: '../:*', local: at, extension: 'zip'),
      'Project-270926-080509.zip',
    );
  });
}
