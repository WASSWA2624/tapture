import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_output_template.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/ooxml_package.dart';
import 'package:tapture/core/export/plain_text_writer.dart';
import 'package:tapture/core/export/template_deliverables.dart';
import 'package:tapture/core/export/word_writer.dart';
import 'package:tapture/core/export/xlsx_template_writer.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/features/exports/data/deliverable_renderer.dart';
import 'package:tapture/features/templates/templates.dart';
import 'package:xml/xml.dart';

import 'template_output_fixture.dart';

void main() {
  test(
    'mapped numeric fields stay numeric for formulas while identifiers remain text',
    () {
      final Map<String, Object?> json = TemplateOutputFixture.record().toJson();
      final List<Map<String, Object?>> values = (json['values']! as List)
          .map((value) => Map<String, Object?>.from(value as Map))
          .toList();
      values.last.addAll(<String, Object?>{
        'type': 'number',
        'finalText': '12.5',
      });
      final ExportRecord record = ExportRecord.fromJson(<String, Object?>{
        ...json,
        'values': values,
      });
      final XmlDocument sheet = OoxmlPackage.open(
        XlsxTemplateWriter.fill(
          source: TemplateOutputFixture.workbook(),
          template: TemplateOutputFixture.template('xlsx'),
          records: <ExportRecord>[record],
        ),
      ).xml('xl/worksheets/register.xml');
      final XmlElement number = sheet
          .findAllElements('c')
          .singleWhere((cell) => cell.getAttribute('r') == 'C7');
      expect(number.getAttribute('t'), 'n');
      expect(number.findElements('v').single.innerText, '12.5');
      final XmlElement identifier = sheet
          .findAllElements('c')
          .singleWhere((cell) => cell.getAttribute('r') == 'B7');
      expect(identifier.getAttribute('t'), 'inlineStr');
      expect(identifier.innerText, '00734');
    },
  );
  test(
    'valid Office fixtures keep all untouched parts including charts and images',
    () {
      for (final String kind in <String>['xlsx', 'docx']) {
        final Uint8List source = File(
          'test/fixtures/export_templates/client.$kind',
        ).readAsBytesSync();
        final OoxmlPackage original = OoxmlPackage.open(source);
        final OoxmlPackage written = OoxmlPackage.open(
          kind == 'xlsx'
              ? XlsxTemplateWriter.fill(
                  source: source,
                  template: TemplateOutputFixture.template(kind),
                  records: <ExportRecord>[TemplateOutputFixture.record()],
                )
              : WordWriter.fill(source, TemplateOutputFixture.record()),
        );
        expect(written.names, original.names);
        for (final String name in original.names.where(
          (name) => kind == 'xlsx'
              ? name != 'xl/worksheets/sheet2.xml'
              : name != 'word/document.xml' && name != 'word/header1.xml',
        )) {
          expect(written.part(name), original.part(name), reason: name);
        }
        expect(
          utf8.decode(
            written.part(
              kind == 'xlsx' ? 'xl/worksheets/sheet2.xml' : 'word/document.xml',
            ),
          ),
          contains('00734'),
        );
        final String part = kind == 'xlsx'
            ? 'xl/worksheets/sheet2.xml'
            : 'word/document.xml';
        final XmlDocument document = written.xml(part);
        final String? namespace = original.xml(part).rootElement.namespaceUri;
        expect(namespace, isNotNull);
        for (final XmlElement element
            in document.descendants.whereType<XmlElement>()) {
          expect(
            element.namespaceUri,
            namespace,
            reason: element.name.qualified,
          );
        }
      }
    },
  );

  test(
    'Word multiline values retain explicit line breaks and each source output shows incomplete status',
    () {
      final Map<String, Object?> json = TemplateOutputFixture.record().toJson();
      final List<Map<String, Object?>> values = (json['values']! as List)
          .map((value) => Map<String, Object?>.from(value as Map))
          .toList();
      values.last['finalText'] = 'First line\r\nSecond line';
      final ExportRecord record = ExportRecord.fromJson(<String, Object?>{
        ...json,
        'values': values,
      });
      final OoxmlPackage word = OoxmlPackage.open(
        WordWriter.fill(
          TemplateOutputFixture.word(),
          record,
          markedIncomplete: true,
        ),
      );
      final XmlDocument document = word.xml('word/document.xml');
      final XmlElement lineBreak = document
          .findAllElements(
            'br',
            namespaceUri: document.rootElement.namespaceUri,
          )
          .single;
      expect(lineBreak.namespacePrefix, document.rootElement.namespacePrefix);
      expect(
        document
            .findAllElements('t', namespaceUri: '*')
            .map((node) => node.innerText),
        contains('Second line'),
      );
      expect(document.toXmlString(), contains('Marked incomplete'));
      final OoxmlPackage workbook = OoxmlPackage.open(
        XlsxTemplateWriter.fill(
          source: TemplateOutputFixture.workbook(),
          template: TemplateOutputFixture.template('xlsx'),
          records: <ExportRecord>[record],
          markedIncomplete: true,
        ),
      );
      expect(
        workbook.xml('xl/worksheets/register.xml').toXmlString(),
        contains('Marked incomplete'),
      );
      expect(
        utf8.decode(
          PlainTextWriter.fill(
            Uint8List.fromList(utf8.encode('{{serial}}\r\n')),
            record,
            markedIncomplete: true,
          ),
        ),
        contains('Marked incomplete\r\n'),
      );
    },
  );

  test('Office archive rejects inflated declared size before opening XML', () {
    final Uint8List source = TemplateOutputFixture.word();
    final ByteData directory = ByteData.sublistView(source);
    final int offset = List<int>.generate(source.length - 4, (index) => index)
        .firstWhere(
          (index) => directory.getUint32(index, Endian.little) == 0x02014b50,
        );
    directory.setUint32(offset + 24, 0xffffffff, Endian.little);
    expect(() => OoxmlPackage.open(source), throwsA(isA<ValidationFailure>()));
  });
  test(
    'Excel updates actual mapped cells without changing styles formulas or other sheets',
    () {
      final Uint8List source = TemplateOutputFixture.workbook();
      final String before = sha256.convert(source).toString();
      final Map<String, String> original = TemplateOutputFixture.parts(source);
      final Uint8List output = XlsxTemplateWriter.fill(
        source: source,
        template: TemplateOutputFixture.template('xlsx'),
        records: <ExportRecord>[TemplateOutputFixture.record()],
      );
      final Map<String, String> written = TemplateOutputFixture.parts(output);
      for (final String name in original.keys.where(
        (name) => name != 'xl/worksheets/register.xml',
      )) {
        expect(written[name], original[name], reason: name);
      }
      final XmlDocument sheet = XmlDocument.parse(
        written['xl/worksheets/register.xml']!,
      );
      final XmlElement serial = sheet
          .findAllElements('c')
          .singleWhere((cell) => cell.getAttribute('r') == 'B7');
      expect(serial.getAttribute('s'), '4');
      expect(serial.getAttribute('t'), 'inlineStr');
      expect(serial.innerText, '00734');
      expect(
        written['xl/worksheets/register.xml'],
        contains('<f>SUM(A1:A3)</f><v>23</v>'),
      );
      expect(
        sheet
            .findAllElements('c')
            .singleWhere((cell) => cell.getAttribute('r') == 'C7')
            .innerText,
        'Pump & motor <west>',
      );
      expect(
        written['xl/worksheets/register.xml'],
        contains('<c r="B8" s="4"/>'),
      );
      expect(sha256.convert(source).toString(), before);
    },
  );

  test(
    'Excel refuses formula targets and two records assigned to the same row',
    () {
      expect(
        () => XlsxTemplateWriter.fill(
          source: TemplateOutputFixture.workbook(formulaTarget: true),
          template: TemplateOutputFixture.template('xlsx'),
          records: <ExportRecord>[TemplateOutputFixture.record()],
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => XlsxTemplateWriter.fill(
          source: TemplateOutputFixture.workbook(),
          template: TemplateOutputFixture.template('xlsx'),
          records: <ExportRecord>[
            TemplateOutputFixture.record(),
            TemplateOutputFixture.record(id: 'second'),
          ],
        ),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );

  test(
    'Word replaces split placeholders and retains styles headers images and page setup',
    () {
      final Uint8List source = TemplateOutputFixture.word();
      final Map<String, String> original = TemplateOutputFixture.parts(source);
      expect(WordWriter.fields(source), <String>{
        'serial',
        'description',
        'unknown',
      });
      final Map<String, String> output = TemplateOutputFixture.parts(
        WordWriter.fill(source, TemplateOutputFixture.record()),
      );
      expect(output['word/styles.xml'], original['word/styles.xml']);
      expect(
        output['word/media/image1.png'],
        original['word/media/image1.png'],
      );
      final XmlDocument body = XmlDocument.parse(output['word/document.xml']!);
      expect(
        body
            .findAllElements('t', namespaceUri: '*')
            .map((node) => node.innerText)
            .join(),
        'Asset 00734: Pump & motor <west>Missing ',
      );
      expect(
        output['word/document.xml'],
        contains('<w:pStyle w:val="ClientTitle"/>'),
      );
      expect(
        output['word/document.xml'],
        contains('<w:pgSz w:w="11906" w:h="16838"/>'),
      );
      expect(output['word/header1.xml'], contains('Reference 00734'));
      for (final XmlElement text in body.findAllElements(
        't',
        namespaceUri: '*',
      )) {
        expect(
          text.attributes
              .where((attribute) => attribute.name.local == 'space')
              .length,
          1,
        );
        expect(
          text.attributes
              .singleWhere((attribute) => attribute.name.local == 'space')
              .name
              .prefix,
          'xml',
        );
        expect(
          text.attributes
              .singleWhere((attribute) => attribute.name.local == 'space')
              .namespaceUri,
          'http://www.w3.org/XML/1998/namespace',
        );
      }
      expect(TemplateOutputFixture.parts(source), original);
    },
  );

  test(
    'plain text keeps source whitespace and Unicode while missing placeholders remain empty',
    () {
      final Uint8List source = Uint8List.fromList(
        utf8.encode(
          'Client\r\n\t{{serial}} — {{description}}\r\nMissing: {{unknown}}\r\n',
        ),
      );
      expect(
        utf8.decode(
          PlainTextWriter.fill(source, TemplateOutputFixture.record()),
        ),
        'Client\r\n\t00734 — Pump & motor <west>\r\nMissing: \r\n',
      );
      expect(
        () => PlainTextWriter.decode(Uint8List.fromList(<int>[65, 0, 66])),
        throwsFormatException,
      );
    },
  );

  test(
    'source templates and mappings survive an export request round trip',
    () {
      final ExportRequest request = TemplateOutputFixture.request(
        templates: <ExportOutputTemplate>[
          TemplateOutputFixture.template('xlsx'),
        ],
      );
      expect(
        ExportRequest.fromJson(request.toJson()).toJson(),
        request.toJson(),
      );
    },
  );

  test(
    'template output names missing checklist rows and unmatched grouping without guessing a row',
    () {
      final ExportOutputTemplate template = TemplateOutputFixture.template(
        'xlsx',
      );
      final ExportRequest request =
          TemplateOutputFixture.request(
            templates: <ExportOutputTemplate>[template],
          ).copyWith(
            records: <ExportRecord>[
              TemplateOutputFixture.record(row: 'uncertain'),
            ],
          );
      final Map<String, Uint8List> output = TemplateDeliverables.render(
        request,
        <String, Uint8List>{template.key: TemplateOutputFixture.workbook()},
      );
      final List<Object?> report =
          jsonDecode(utf8.decode(output['template-output-summary.json']!))
              as List<Object?>;
      final Map<String, Object?> summary = Map<String, Object?>.from(
        report.single! as Map,
      );
      expect(summary['notCapturedRowIds'], <String>['row-seven', 'row-eight']);
      expect(summary['unmatchedRecordIds'], <String>['record']);
    },
  );

  test('a changed template hash is refused before any file is emitted', () {
    const ExportOutputTemplate template = ExportOutputTemplate(
      templateId: 'template',
      templateVersion: '1',
      sourcePath: 'source.txt',
      kind: 'txt',
      sourceHash: 'wrong',
    );
    expect(
      () => TemplateDeliverables.render(
        TemplateOutputFixture.request(
          templates: <ExportOutputTemplate>[template],
        ),
        <String, Uint8List>{
          template.key: Uint8List.fromList(utf8.encode('{{serial}}')),
        },
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test(
    'Word and text template import derives fields from the real source and rejects binary input',
    () async {
      for (final PickedBytes source in <PickedBytes>[
        PickedBytes(TemplateOutputFixture.word(), 'client.docx'),
        PickedBytes(
          Uint8List.fromList(utf8.encode('{{serial}} {{description}}')),
          'client.txt',
        ),
      ]) {
        final TemplateDef draft = (await TemplateDocumentImport.output(
          source,
          projectId: 'project',
        )).getOrThrow();
        expect(
          draft.fields.map((field) => field.fieldKey),
          containsAll(<String>['serial', 'description']),
        );
        expect(draft.projectId, 'project');
      }
      expect(
        await TemplateDocumentImport.output(
          PickedBytes(Uint8List.fromList(<int>[1, 0, 2]), 'client.txt'),
          projectId: 'project',
        ),
        isA<FailureResult<TemplateDef>>(),
      );
    },
  );

  test(
    'Office XML refuses document types rather than resolving attached instructions',
    () {
      final Uint8List bytes = TemplateOutputFixture.zip(<String, String>{
        '[Content_Types].xml': '<Types/>',
        '_rels/.rels': '<Relationships/>',
        'word/document.xml':
            '<!DOCTYPE document SYSTEM "https://invalid.example/payload"><document/>',
      });
      expect(
        () => OoxmlPackage.open(bytes).xml('word/document.xml'),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );

  test(
    'renderer produces Word text and imported workbook files from one captured record snapshot',
    () async {
      final ExportOutputTemplate template = TemplateOutputFixture.template(
        'xlsx',
      );
      final Uint8List source = TemplateOutputFixture.workbook();
      final DeliverableRenderer renderer = DeliverableRenderer(
        files: FileReader.memory(<String, Uint8List>{
          template.sourcePath: source,
        }),
      );
      final Map<String, Uint8List> files = (await renderer.render(
        TemplateOutputFixture.request(
          templates: <ExportOutputTemplate>[template],
        ),
        createdAt: DateTime.utc(2026),
        cancel: CancellationToken(),
      )).getOrThrow();
      expect(
        files.keys,
        containsAll(<String>[
          'records.xlsx',
          'records.docx',
          'records.txt',
          'template-template-v1.xlsx',
        ]),
      );
      expect(utf8.decode(files['records.txt']!), contains('00734'));
      expect(
        TemplateOutputFixture.parts(
          files['records.docx']!,
        )['word/document.xml'],
        contains('00734'),
      );
      final CancellationToken cancel = CancellationToken()..cancel();
      expect(
        await renderer.render(
          TemplateOutputFixture.request(
            templates: <ExportOutputTemplate>[template],
          ),
          createdAt: DateTime.utc(2026),
          cancel: cancel,
        ),
        isA<FailureResult<Map<String, Uint8List>>>(),
      );
    },
  );
}
