import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/hash/hashing_service.dart';
import 'package:tapture/features/projects/projects.dart' show Project;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  late Directory documents;
  late StorageRoot storage;
  late FakeTemplateRepository templates;

  setUp(() {
    documents = Directory.systemTemp.createTempSync('tapture-xlsx-import-');
    storage = StorageRoot.fake(documentsDirectory: documents);
    templates = FakeTemplateRepository();
  });

  tearDown(() {
    templates.dispose();
    if (documents.existsSync()) {
      documents.deleteSync(recursive: true);
    }
  });

  test('the copied workbook matches the original hash after import', () async {
    final Project project = aProject();
    final File source = File('${documents.path}/register.xlsx');
    source.writeAsBytesSync(_workbook());
    final String before = _ok(await HashingService.sha256OfFile(source));
    final XlsxTemplateImport importer = XlsxTemplateImport(
      storageRoot: storage,
      folders: ProjectFolders(storageRoot: storage),
      writer: FileWriter(storageRoot: storage),
      templates: templates,
    );

    expect(templates.count, 0);
    final TemplateDef saved = _ok(
      await importer.apply(
        projectId: project.id,
        projectName: project.name,
        folderName: project.folderName,
        path: source.path,
        draft: _draft(project),
      ),
    );

    expect(templates.count, 1);
    expect(_ok(await HashingService.sha256OfFile(source)), before);
    expect(saved.source, 'imported');
    expect(saved.sheetName, 'Register');
    expect(saved.headerRow, 1);
    expect(saved.sourceFilePath, isNotNull);
    expect(saved.sourceFilePath, contains('templates/'));
    expect(saved.fields.map((FieldDef field) => field.outputColumn), <String>[
      'A',
      'B',
    ]);
    final File copy = File('${documents.path}/Tapture/${saved.sourceFilePath}');
    expect(copy.existsSync(), isTrue);
    expect(_ok(await HashingService.sha256OfFile(copy)), before);
    expect(copy.readAsBytesSync(), source.readAsBytesSync());
  });
}

TemplateDef _draft(Project project) {
  return aTemplate(
    id: '',
    name: 'Register',
    projectId: project.id,
    fields: const <FieldDef>[
      FieldDef(
        fieldKey: 'asset_tag',
        label: 'Asset tag',
        type: FieldType.text,
        outputColumn: 'A',
      ),
      FieldDef(
        fieldKey: 'serial',
        label: 'Serial',
        type: FieldType.number,
        outputColumn: 'B',
      ),
    ],
  ).copyWith(sheetName: 'Register', headerRow: 1, source: 'imported');
}

Uint8List _workbook() {
  return XlsxEncoder.encode(
    XlsxBook(
      createdUtc: DateTime.utc(2026, 9, 20, 8),
      sheets: const <XlsxSheet>[
        XlsxSheet(
          name: 'Register',
          columns: <XlsxColumn>[XlsxColumn('Asset tag'), XlsxColumn('Serial')],
          rows: <List<XlsxCell>>[
            <XlsxCell>[XlsxCell.text('A-1'), XlsxCell.number(100)],
          ],
        ),
      ],
    ),
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
