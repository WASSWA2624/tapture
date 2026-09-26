import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/ai/ocr_service.dart';
import 'package:tapture/core/constants/app_constants.dart';

void main() {
  test('a result that does not name its reader is unspecified', () {
    const OcrResult result = OcrResult(text: 'SN1', blocks: <OcrBlock>[]);

    expect(result.engine, AppConstants.ocrEngineUnspecified);
  });

  test('the desktop reader names itself on its result', () async {
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_ocr_engine_',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final File plate = File('${directory.path}/plate.png')
      ..writeAsBytesSync(OcrService.paintPlate('SN1'));

    final OcrResult result = await OcrService().recognise(plate.path);

    expect(result.text, 'SN1');
    expect(result.engine, AppConstants.processing.ocrEngineDesktop);
  });
}
