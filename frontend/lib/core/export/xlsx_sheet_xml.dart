part of 'xlsx_encoder.dart';

/// Cell styles, by their index in `styles.xml` (see [_stylesXml]).
const int _styleBody = 1;
const int _styleDate = 2;
const int _styleWrap = 3;
const int _styleHeader = 4;
const int _styleHeaderWrap = 5;
const int _styleLink = 6;

/// Pixels to the drawing unit spreadsheets measure pictures in (EMU).
const int _emuPerPixel = 9525;

/// Gap between a picture and the top-left corner of its cell, in pixels.
const int _imageInset = 4;

String _sheetXml(
  XlsxSheet sheet,
  _SharedStrings strings, {
  required bool selected,
  required bool drawing,
}) {
  final int columns = _columnCount(sheet);
  final int lastRow = sheet.rows.length + 1;
  final String lastColumn = XlsxSheet.columnName(columns - 1);
  final List<String> links = <String>[];
  final StringBuffer xml = StringBuffer(_xmlHead)
    ..write('<worksheet xmlns="$_mainNs" xmlns:r="$_relNs">')
    ..write('<dimension ref="A1:$lastColumn$lastRow"/>')
    ..write(_sheetViewXml(freeze: sheet.freezeHeader, selected: selected))
    ..write('<sheetFormatPr defaultRowHeight="15"/>')
    ..write(_colsXml(sheet.columns))
    ..write('<sheetData>')
    ..write(_headerRowXml(sheet, strings));
  for (int index = 0; index < sheet.rows.length; index++) {
    xml.write(_rowXml(sheet, index + 1, strings, links));
  }
  xml.write('</sheetData>');
  if (sheet.autoFilter) {
    xml.write('<autoFilter ref="A1:$lastColumn$lastRow"/>');
  }
  if (links.isNotEmpty) {
    xml
      ..write('<hyperlinks>')
      ..writeAll(links)
      ..write('</hyperlinks>');
  }
  xml.write(
    '<pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" '
    'header="0.3" footer="0.3"/>',
  );
  if (drawing) {
    xml.write('<drawing r:id="rId1"/>');
  }
  xml.write('</worksheet>');
  return xml.toString();
}

int _columnCount(XlsxSheet sheet) {
  int count = sheet.columns.length;
  for (final List<XlsxCell> row in sheet.rows) {
    if (row.length > count) {
      count = row.length;
    }
  }
  return count < 1 ? 1 : count;
}

String _sheetViewXml({required bool freeze, required bool selected}) {
  final String tab = selected ? ' tabSelected="1"' : '';
  if (!freeze) {
    return '<sheetViews><sheetView workbookViewId="0"$tab/></sheetViews>';
  }
  return '<sheetViews><sheetView workbookViewId="0"$tab>'
      '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" '
      'state="frozen"/>'
      '<selection pane="bottomLeft" activeCell="A2" sqref="A2"/>'
      '</sheetView></sheetViews>';
}

String _colsXml(List<XlsxColumn> columns) {
  if (columns.isEmpty) {
    return '';
  }
  final StringBuffer xml = StringBuffer('<cols>');
  for (int index = 0; index < columns.length; index++) {
    final XlsxColumn column = columns[index];
    final int style = column.wrap ? _styleWrap : _styleBody;
    xml.write(
      '<col min="${index + 1}" max="${index + 1}" '
      'width="${_decimal(column.width)}" style="$style" customWidth="1"/>',
    );
  }
  xml.write('</cols>');
  return xml.toString();
}

String _headerRowXml(XlsxSheet sheet, _SharedStrings strings) {
  final StringBuffer xml = StringBuffer(
    '<row r="1"${_heightAttributes(sheet.rowHeights[0])}>',
  );
  for (int index = 0; index < sheet.columns.length; index++) {
    final XlsxColumn column = sheet.columns[index];
    final int style = column.wrap ? _styleHeaderWrap : _styleHeader;
    xml.write(
      '<c r="${XlsxSheet.cellName(0, index)}" s="$style" t="s">'
      '<v>${strings.indexOf(column.header)}</v></c>',
    );
  }
  xml.write('</row>');
  return xml.toString();
}

String _rowXml(
  XlsxSheet sheet,
  int row,
  _SharedStrings strings,
  List<String> links,
) {
  final List<XlsxCell> cells = sheet.rows[row - 1];
  final StringBuffer xml = StringBuffer(
    '<row r="${row + 1}"${_heightAttributes(sheet.rowHeights[row])}>',
  );
  for (int column = 0; column < cells.length; column++) {
    final XlsxCell cell = cells[column];
    final String ref = XlsxSheet.cellName(row, column);
    final bool wrap =
        column < sheet.columns.length && sheet.columns[column].wrap;
    final int bodyStyle = wrap ? _styleWrap : _styleBody;
    switch (cell.kind) {
      case XlsxCellKind.empty:
        continue;
      case XlsxCellKind.text:
        xml.write(
          '<c r="$ref" s="$bodyStyle" t="s">'
          '<v>${strings.indexOf(cell.text!)}</v></c>',
        );
      case XlsxCellKind.number:
        final String? number = _numberText(cell.number!);
        if (number != null) {
          xml.write('<c r="$ref" s="$bodyStyle"><v>$number</v></c>');
        }
      case XlsxCellKind.dateTime:
        xml.write(
          '<c r="$ref" s="$_styleDate"><v>${_serial(cell.dateTime!)}</v></c>',
        );
      case XlsxCellKind.link:
        xml.write(
          '<c r="$ref" s="$_styleLink" t="s">'
          '<v>${strings.indexOf(cell.text!)}</v></c>',
        );
        links.add(
          '<hyperlink ref="$ref" '
          'location="${_escape(_sheetRef(cell.linkSheet!, cell.linkCell!))}" '
          'display="${_escape(cell.text!)}"/>',
        );
    }
  }
  xml.write('</row>');
  return xml.toString();
}

String _heightAttributes(double? points) {
  if (points == null || points <= 0) {
    return '';
  }
  return ' ht="${_decimal(points)}" customHeight="1"';
}

/// `'Sheet name'!A1`, with any quote in the name doubled.
String _sheetRef(String sheet, String cell) {
  return "'${sheet.replaceAll("'", "''")}'!$cell";
}

String? _numberText(num value) {
  if (value is int) {
    return value.toString();
  }
  final double number = value.toDouble();
  if (!number.isFinite) {
    return null;
  }
  return _decimal(number);
}

String _decimal(double value) {
  if (value == value.roundToDouble() && value.abs() < _exactIntegers) {
    return value.round().toString();
  }
  return value.toString();
}

/// Doubles hold every integer below this exactly.
const double _exactIntegers = 9007199254740992;

/// Days since the spreadsheet epoch (30 December 1899) for a wall-clock
/// [value], with the time of day as the fraction.
String _serial(DateTime value) {
  final DateTime wall = DateTime.utc(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
  );
  final int millis = wall.difference(_epoch).inMilliseconds;
  final double days = millis / Duration.millisecondsPerDay;
  return _decimal(double.parse(days.toStringAsFixed(_serialDigits)));
}

final DateTime _epoch = DateTime.utc(1899, 12, 30);

/// Eight places resolve a serial to under a millisecond.
const int _serialDigits = 8;

String _drawingXml(List<XlsxImage> images) {
  final StringBuffer xml = StringBuffer(_xmlHead)
    ..write('<xdr:wsDr xmlns:xdr="$_drawingNs" xmlns:a="$_dmlNs" ')
    ..write('xmlns:r="$_relNs">');
  for (int index = 0; index < images.length; index++) {
    final XlsxImage image = images[index];
    final int cx = image.width * _emuPerPixel;
    final int cy = image.height * _emuPerPixel;
    const int inset = _imageInset * _emuPerPixel;
    xml.write(
      '<xdr:oneCellAnchor>'
      '<xdr:from><xdr:col>${image.column}</xdr:col>'
      '<xdr:colOff>$inset</xdr:colOff><xdr:row>${image.row}</xdr:row>'
      '<xdr:rowOff>$inset</xdr:rowOff></xdr:from>'
      '<xdr:ext cx="$cx" cy="$cy"/>'
      '<xdr:pic><xdr:nvPicPr>'
      '<xdr:cNvPr id="${index + 2}" name="Picture ${index + 1}"/>'
      '<xdr:cNvPicPr><a:picLocks noChangeAspect="1"/></xdr:cNvPicPr>'
      '</xdr:nvPicPr>'
      '<xdr:blipFill><a:blip r:embed="rId${index + 1}"/>'
      '<a:stretch><a:fillRect/></a:stretch></xdr:blipFill>'
      '<xdr:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/>'
      '</a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></xdr:spPr>'
      '</xdr:pic><xdr:clientData/></xdr:oneCellAnchor>',
    );
  }
  xml.write('</xdr:wsDr>');
  return xml.toString();
}

String _drawingRelsXml(int firstMedia, int count) {
  final StringBuffer xml = StringBuffer(_xmlHead)
    ..write('<Relationships xmlns="$_packageRelNs">');
  for (int index = 0; index < count; index++) {
    xml.write(
      '<Relationship Id="rId${index + 1}" Type="$_relNs/image" '
      'Target="../media/image${firstMedia + index}.png"/>',
    );
  }
  xml.write('</Relationships>');
  return xml.toString();
}

String _sheetRelsXml(int drawing) {
  return '$_xmlHead<Relationships xmlns="$_packageRelNs">'
      '<Relationship Id="rId1" Type="$_relNs/drawing" '
      'Target="../drawings/drawing$drawing.xml"/></Relationships>';
}
