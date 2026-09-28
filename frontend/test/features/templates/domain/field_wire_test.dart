import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/field_wire.dart';

void main() {
  test(
    'every field type and input mode round trips its canonical wire name',
    () {
      for (final FieldType type in FieldType.values) {
        expect(
          FieldWire.fieldTypeFromWire(FieldWire.fieldTypeToWire(type)),
          type,
        );
      }
      for (final InputMode mode in InputMode.values) {
        expect(
          FieldWire.inputModeFromWire(FieldWire.inputModeToWire(mode)),
          mode,
        );
      }
      expect(
        () => FieldWire.fieldTypeFromWire('made-up'),
        throwsA(isA<Failure>()),
      );
      expect(
        () => FieldWire.inputModeFromWire('made-up'),
        throwsA(isA<Failure>()),
      );
    },
  );
}
