import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:tapture/core/export/export_output_template.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';

/// Small real Office packages, containing styles, formulas and split text runs.
abstract final class TemplateOutputFixture {
  static ExportRequest request({
    List<ExportOutputTemplate> templates = const <ExportOutputTemplate>[],
  }) => ExportRequest(
    projectId: 'project',
    formats: const <ExportFormat>{
      ExportFormat.xlsx,
      ExportFormat.docx,
      ExportFormat.txt,
    },
    scope: (
      kind: ExportScopeKind.approved,
      context: null,
      from: null,
      to: null,
      filter: null,
    ),
    columns: (raw: false, refined: false, confidence: false, evidence: false),
    extras: (
      dictionary: false,
      photoIndex: false,
      photoMode: 'filename',
      pdfPhotos: 'thumbnail',
      delimiter: ',',
    ),
    records: <ExportRecord>[record()],
    outputTemplates: templates,
  );

  static ExportRecord record({
    String id = 'record',
    String row = 'row-seven',
  }) => ExportRecord(
    id: id,
    number: '00734',
    templateId: 'template',
    templateVersion: '1',
    templateName: 'Client asset',
    status: 'approved',
    approved: true,
    templateRowId: row,
    values: const <ExportValue>[
      (
        key: 'serial',
        label: 'Serial',
        type: 'identifier',
        raw: '00734',
        refined: null,
        finalText: '00734',
        unit: null,
        code: null,
        confidence: null,
        evidence: null,
      ),
      (
        key: 'description',
        label: 'Description',
        type: 'text',
        raw: 'Pump & motor <west>',
        refined: null,
        finalText: 'Pump & motor <west>',
        unit: null,
        code: null,
        confidence: null,
        evidence: null,
      ),
    ],
  );

  static ExportOutputTemplate template(String kind) => ExportOutputTemplate(
    templateId: 'template',
    templateVersion: '1',
    sourcePath: 'projects/project/templates/source.$kind',
    kind: kind,
    sheetName: 'Register',
    headerRow: 3,
    columns: const <String, String>{'serial': 'B', 'description': 'C'},
    rows: const <String, int>{'row-seven': 7, 'row-eight': 8},
  );

  static Uint8List workbook({
    bool formulaTarget = false,
  }) => zip(<String, String>{
    '[Content_Types].xml':
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"/>',
    '_rels/.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>',
    'xl/workbook.xml':
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Cover" sheetId="1" r:id="cover"/><sheet r:id="register" sheetId="2" name="Register"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Target="worksheets/cover.xml" Id="cover"/><Relationship Target="worksheets/register.xml" Id="register"/></Relationships>',
    'xl/styles.xml':
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="1"><font><b/></font></fonts></styleSheet>',
    'xl/worksheets/cover.xml':
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData><row r="1"><c r="A1" t="inlineStr"><is><t>Client cover</t></is></c></row></sheetData></worksheet>',
    'xl/worksheets/register.xml':
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><dimension ref="A1:E8"/><sheetData><row r="3"><c r="B3" t="inlineStr"><is><t>Serial</t></is></c></row><row r="7" ht="42" customHeight="1"><c r="B7" s="4">${formulaTarget ? '<f>SUM(A1:A3)</f>' : '<v>9</v>'}</c><c r="D7"><f>SUM(A1:A3)</f><v>23</v></c></row><row r="8"><c r="B8" s="4"/></row></sheetData><mergeCells><mergeCell ref="A1:E1"/></mergeCells><pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/></worksheet>',
    'xl/charts/chart1.xml': '<chart>Retain this exact part</chart>',
  });

  static Uint8List word() => zip(<String, String>{
    '[Content_Types].xml':
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"/>',
    '_rels/.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>',
    'word/document.xml':
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:pPr><w:pStyle w:val="ClientTitle"/></w:pPr><w:r><w:rPr><w:b/></w:rPr><w:t>Asset {{ser</w:t></w:r><w:r><w:t>ial}}: {{description}}</w:t></w:r></w:p><w:p><w:r><w:t>Missing {{unknown}}</w:t></w:r></w:p><w:sectPr><w:pgSz w:w="11906" w:h="16838"/></w:sectPr></w:body></w:document>',
    'word/styles.xml':
        '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:style w:styleId="ClientTitle"/></w:styles>',
    'word/header1.xml':
        '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:r><w:t>Reference {{serial}}</w:t></w:r></w:p></w:hdr>',
    'word/media/image1.png': 'unchanged client logo bytes',
  });

  static Uint8List zip(Map<String, String> parts) {
    final Archive archive = Archive();
    for (final MapEntry<String, String> part in parts.entries) {
      final List<int> bytes = utf8.encode(part.value);
      archive.addFile(ArchiveFile(part.key, bytes.length, bytes));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  static Map<String, String> parts(Uint8List bytes) => <String, String>{
    for (final ArchiveFile file
        in ZipDecoder().decodeBytes(bytes, verify: true).files)
      file.name: utf8.decode(file.content as List<int>),
  };
}
