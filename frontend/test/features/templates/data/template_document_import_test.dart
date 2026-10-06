import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';

void main() {
  test(
    'browser JSON preserves fields, checklist positions and aliases',
    () async {
      final TemplateDef original = aTemplate().copyWith(
        rows: const <TemplateRow>[
          TemplateRow(
            identifier: 'bp',
            label: 'Blood pressure',
            outputRowNumber: 7,
            aliases: <String>['BP', 'Pressure'],
          ),
        ],
      );
      final Result<TemplateDef> result = await TemplateDocumentImport.json(
        _bytes(jsonEncode(TemplateJson.encode(original)), 'template.json'),
        projectId: 'new-project',
      );
      final TemplateDef draft = result.getOrThrow();
      expect(draft.projectId, 'new-project');
      expect(draft.fields, original.fields);
      expect(draft.rows, original.rows);
    },
  );

  test(
    'unsupported extension, oversized input and rejected schema write no draft',
    () async {
      expect(
        await TemplateDocumentImport.validate(_bytes('{}', 'template.exe')),
        isA<FailureResult<void>>(),
      );
      expect(
        await TemplateDocumentImport.validate(
          PickedBytes(
            Uint8List(AppConstants.imports.spreadsheetMaxBytes + 1),
            'template.json',
          ),
        ),
        isA<FailureResult<void>>(),
      );
      expect(
        await TemplateDocumentImport.json(
          _bytes('{"schema_version":99}', 'template.json'),
          projectId: 'project-1',
        ),
        isA<FailureResult<TemplateDef>>(),
      );
    },
  );

  test(
    'CSV browser bytes reuse the workbook reader and cancellation is typed',
    () async {
      final PickedDocument document = _bytes(
        'Identifier,Label,Aliases\nBP,Pressure,BP machine\n',
        'checklist.csv',
      );
      final book = (await TemplateDocumentImport.workbook(
        document,
      )).getOrThrow();
      expect(book.sheets.single.rows.last, <String>[
        'BP',
        'Pressure',
        'BP machine',
      ]);
      final CancellationToken cancel = CancellationToken()..cancel();
      final result = await TemplateDocumentImport.workbook(
        document,
        cancel: cancel,
      );
      expect(result, isA<FailureResult<Object>>());
      expect(
        result.fold((Failure failure) => failure, (_) => null),
        isA<CancelledFailure>(),
      );
    },
  );

  test(
    'cleanup removes an owned picker copy and preserves an original',
    () async {
      final Directory temp = Directory.systemTemp.createTempSync(
        'tapture-document-import-',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      final File original = File('${temp.path}/original.csv')
        ..writeAsStringSync('A\nB');
      final File copy = File('${temp.path}/copy.csv')
        ..writeAsStringSync('A\nB');
      await TemplateDocumentImport.discard(
        PickedFile(original, 'original.csv', original.lengthSync()),
      );
      await TemplateDocumentImport.discard(
        PickedFile(copy, 'copy.csv', copy.lengthSync(), isCopy: true),
      );
      expect(original.readAsStringSync(), 'A\nB');
      expect(copy.existsSync(), isFalse);
    },
  );
}

PickedBytes _bytes(String value, String name) =>
    PickedBytes(Uint8List.fromList(utf8.encode(value)), name);
