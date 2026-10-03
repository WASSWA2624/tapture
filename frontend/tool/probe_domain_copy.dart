import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/context/domain/context_repository.dart';
import 'package:tapture/features/reference/domain/lookup_binding.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/field_type_registry.dart';

import 'domain_copy_imports.g.dart';

/// Runs with plain `dart run`, so any transitive dart:ui import fails compilation.
void main() {
  verifyDomainImports();
  if (presetNameTaken.message != 'A preset with that name already exists.') {
    throw StateError('Changed preset audit fallback');
  }
  final LocalizedMessage? lookup = LookupBinding.validationMessage(
    binding: const LookupBinding(
      datasetId: 'd',
      matchColumns: <String>['id'],
      fillMapping: <String, String>{'id': 'missing'},
    ),
    templateFieldKeys: <String>{'serial'},
  );
  if (lookup == null || lookup.key != 'lookupUnknownTarget') {
    throw StateError('Missing lookup semantic key');
  }
  final Failure? badNumber = FieldTypeRegistry.validate(
    type: FieldType.number,
    field: const FieldDef(
      fieldKey: 'n',
      label: 'Number',
      type: FieldType.number,
    ),
    value: 'not a number',
  ).fold((Failure failure) => failure, (_) => null);
  if (badNumber?.localizedMessage == null) {
    throw StateError('Missing typed field semantic message');
  }
  if (DomainCopy.messages.captureNeedsEvidence.fallback !=
      DomainCopy.captureNeedsEvidence) {
    throw StateError('Changed evidence audit copy');
  }
}
