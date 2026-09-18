part of 'xlsx_encoder.dart';

const String _xmlHead =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';

const String _mainNs =
    'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const String _relNs =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const String _packageRelNs =
    'http://schemas.openxmlformats.org/package/2006/relationships';
const String _drawingNs =
    'http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing';
const String _dmlNs = 'http://schemas.openxmlformats.org/drawingml/2006/main';
const String _officeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml';

String _contentTypesXml(int sheets, int drawings, {required bool hasMedia}) {
  final StringBuffer xml = StringBuffer(_xmlHead)
    ..write(
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/'
      'content-types">',
    )
    ..write(
      '<Default Extension="rels" '
      'ContentType="application/vnd.openxmlformats-package.relationships+xml"'
      '/>',
    )
    ..write('<Default Extension="xml" ContentType="application/xml"/>');
  if (hasMedia) {
    xml.write('<Default Extension="png" ContentType="image/png"/>');
  }
  xml.write(
    '<Override PartName="/xl/workbook.xml" '
    'ContentType="$_officeType.sheet.main+xml"/>',
  );
  for (int index = 1; index <= sheets; index++) {
    xml.write(
      '<Override PartName="/xl/worksheets/sheet$index.xml" '
      'ContentType="$_officeType.worksheet+xml"/>',
    );
  }
  for (int index = 1; index <= drawings; index++) {
    xml.write(
      '<Override PartName="/xl/drawings/drawing$index.xml" '
      'ContentType="application/vnd.openxmlformats-officedocument.'
      'drawing+xml"/>',
    );
  }
  xml
    ..write(
      '<Override PartName="/xl/styles.xml" '
      'ContentType="$_officeType.styles+xml"/>',
    )
    ..write(
      '<Override PartName="/xl/sharedStrings.xml" '
      'ContentType="$_officeType.sharedStrings+xml"/>',
    )
    ..write(
      '<Override PartName="/docProps/core.xml" '
      'ContentType="application/vnd.openxmlformats-package.'
      'core-properties+xml"/>',
    )
    ..write(
      '<Override PartName="/docProps/app.xml" '
      'ContentType="application/vnd.openxmlformats-officedocument.'
      'extended-properties+xml"/>',
    )
    ..write('</Types>');
  return xml.toString();
}

const String _rootRelsXml =
    '$_xmlHead<Relationships xmlns="$_packageRelNs">'
    '<Relationship Id="rId1" Type="$_relNs/officeDocument" '
    'Target="xl/workbook.xml"/>'
    '<Relationship Id="rId2" '
    'Type="$_packageRelNs/metadata/core-properties" '
    'Target="docProps/core.xml"/>'
    '<Relationship Id="rId3" Type="$_relNs/extended-properties" '
    'Target="docProps/app.xml"/>'
    '</Relationships>';

String _workbookXml(List<XlsxSheet> sheets) {
  final StringBuffer xml = StringBuffer(_xmlHead)
    ..write('<workbook xmlns="$_mainNs" xmlns:r="$_relNs">')
    ..write('<bookViews><workbookView activeTab="0"/></bookViews><sheets>');
  for (int index = 0; index < sheets.length; index++) {
    xml.write(
      '<sheet name="${_escape(sheets[index].name)}" '
      'sheetId="${index + 1}" r:id="rId${index + 1}"/>',
    );
  }
  xml.write('</sheets></workbook>');
  return xml.toString();
}

String _workbookRelsXml(int sheets) {
  final StringBuffer xml = StringBuffer(_xmlHead)
    ..write('<Relationships xmlns="$_packageRelNs">');
  for (int index = 1; index <= sheets; index++) {
    xml.write(
      '<Relationship Id="rId$index" Type="$_relNs/worksheet" '
      'Target="worksheets/sheet$index.xml"/>',
    );
  }
  xml
    ..write(
      '<Relationship Id="rId${sheets + 1}" Type="$_relNs/styles" '
      'Target="styles.xml"/>',
    )
    ..write(
      '<Relationship Id="rId${sheets + 2}" Type="$_relNs/sharedStrings" '
      'Target="sharedStrings.xml"/>',
    )
    ..write('</Relationships>');
  return xml.toString();
}

/// Fonts: 0 body, 1 bold header, 2 link. The cell formats are indexed by
/// the `_style…` constants in the sheet part.
String _stylesXml(String dateTimeFormat) {
  return '$_xmlHead<styleSheet xmlns="$_mainNs">'
      '<numFmts count="1"><numFmt numFmtId="164" '
      'formatCode="${_escape(dateTimeFormat)}"/></numFmts>'
      '<fonts count="3">'
      '<font><sz val="11"/><color theme="1"/><name val="Calibri"/>'
      '<family val="2"/><scheme val="minor"/></font>'
      '<font><b/><sz val="11"/><color theme="1"/><name val="Calibri"/>'
      '<family val="2"/><scheme val="minor"/></font>'
      '<font><u/><sz val="11"/><color theme="10"/><name val="Calibri"/>'
      '<family val="2"/><scheme val="minor"/></font>'
      '</fonts>'
      '<fills count="2"><fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill></fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/>'
      '</border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" '
      'borderId="0"/></cellStyleXfs>'
      '<cellXfs count="7">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '${_xf(fontId: 0)}'
      '${_xf(fontId: 0, numFmtId: 164)}'
      '${_xf(fontId: 0, wrap: true)}'
      '${_xf(fontId: 1)}'
      '${_xf(fontId: 1, wrap: true)}'
      '${_xf(fontId: 2)}'
      '</cellXfs>'
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/>'
      '</cellStyles></styleSheet>';
}

String _xf({required int fontId, int numFmtId = 0, bool wrap = false}) {
  final String number = numFmtId == 0 ? '' : ' applyNumberFormat="1"';
  final String font = fontId == 0 ? '' : ' applyFont="1"';
  final String alignment = wrap
      ? '<alignment vertical="top" wrapText="1"/>'
      : '<alignment vertical="top"/>';
  return '<xf numFmtId="$numFmtId" fontId="$fontId" fillId="0" borderId="0" '
      'xfId="0"$number$font applyAlignment="1">$alignment</xf>';
}

String _coreXml(XlsxBook book) {
  final String stamp = _w3cdtf(book.createdUtc);
  final String creator = _escape(book.creator);
  return '$_xmlHead<cp:coreProperties '
      'xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/'
      'core-properties" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/" '
      'xmlns:dcterms="http://purl.org/dc/terms/" '
      'xmlns:dcmitype="http://purl.org/dc/dcmitype/" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
      '<dc:creator>$creator</dc:creator>'
      '<dc:subject>${_escape(book.subject)}</dc:subject>'
      '<cp:lastModifiedBy>$creator</cp:lastModifiedBy>'
      '<dcterms:created xsi:type="dcterms:W3CDTF">$stamp</dcterms:created>'
      '<dcterms:modified xsi:type="dcterms:W3CDTF">$stamp</dcterms:modified>'
      '</cp:coreProperties>';
}

String _appXml(XlsxBook book) {
  final StringBuffer titles = StringBuffer();
  for (final XlsxSheet sheet in book.sheets) {
    titles.write('<vt:lpstr>${_escape(sheet.name)}</vt:lpstr>');
  }
  final int count = book.sheets.length;
  return '$_xmlHead<Properties '
      'xmlns="http://schemas.openxmlformats.org/officeDocument/2006/'
      'extended-properties" '
      'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/'
      'docPropsVTypes">'
      '<Application>${_escape(book.creator)}</Application>'
      '<HeadingPairs><vt:vector size="2" baseType="variant">'
      '<vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant>'
      '<vt:variant><vt:i4>$count</vt:i4></vt:variant></vt:vector>'
      '</HeadingPairs>'
      '<TitlesOfParts><vt:vector size="$count" baseType="lpstr">$titles'
      '</vt:vector></TitlesOfParts></Properties>';
}

/// `2026-09-18T10:02:00Z` — the property timestamp shape, with no fraction.
String _w3cdtf(DateTime value) {
  final DateTime utc = value.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
      '${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:'
      '${two(utc.second)}Z';
}
