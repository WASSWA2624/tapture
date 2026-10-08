import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/export/xlsx_book.dart';
import 'package:tapture/core/export/xlsx_cell.dart';
import 'package:tapture/core/export/xlsx_column.dart';
import 'package:tapture/core/export/xlsx_encoder.dart';
import 'package:tapture/core/export/xlsx_sheet.dart';

/// Real UTF-8 text and workbook originals for capture attachment tests.
Map<String, Uint8List> captureDocumentOriginals() => <String, Uint8List>{
  'Inspection Équipement.CSV': Uint8List.fromList(
    utf8.encode('serial,notes\r\nSN-1,"Équipement, original"\r\n'),
  ),
  'Inspection Équipement.JSON': Uint8List.fromList(
    utf8.encode('{"serial":"SN-1","notes":"Équipement original"}'),
  ),
  'Inspection Équipement.XLSX': XlsxEncoder.encode(
    XlsxBook(
      createdUtc: DateTime.utc(2026, 9, 30),
      sheets: const <XlsxSheet>[
        XlsxSheet(
          name: 'Original',
          columns: <XlsxColumn>[XlsxColumn('Serial'), XlsxColumn('Notes')],
          rows: <List<XlsxCell>>[
            <XlsxCell>[
              XlsxCell.text('SN-1'),
              XlsxCell.text('Original evidence'),
            ],
          ],
        ),
      ],
    ),
  ),
};
