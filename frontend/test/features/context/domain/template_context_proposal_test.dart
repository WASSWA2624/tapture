import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/context/domain/template_context_proposal.dart';
import 'package:tapture/features/templates/domain/field_def.dart';

import '../../../support/factories.dart';

void main() {
  test('keeps positive levels in stable broad-to-narrow field order', () {
    final proposal = TemplateContextProposal.fromTemplates(<TemplateFactory>[
      aTemplate(
        id: 't1',
        projectId: 'p1',
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'site',
            label: 'Site',
            type: FieldType.text,
            contextLevel: 2,
            sortOrder: 1,
          ),
          FieldDef(
            fieldKey: 'country',
            label: 'Country',
            type: FieldType.text,
            contextLevel: 1,
            sortOrder: 0,
          ),
          FieldDef(
            fieldKey: 'ignored',
            label: 'Ignored',
            type: FieldType.text,
            contextLevel: 0,
          ),
        ],
      ),
    ], projectId: 'p1');

    expect(proposal.levels.map((level) => level.field.fieldKey), <String>[
      'country',
      'site',
    ]);
    expect(proposal.levels.map((level) => level.level), <int>[1, 2]);
    expect(proposal.hasConflicts, isFalse);
  });

  test('reports duplicate levels and conflicting field keys', () {
    final proposal = TemplateContextProposal.fromTemplates(<TemplateFactory>[
      aTemplate(
        id: 't1',
        projectId: 'p1',
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'country',
            label: 'Country',
            type: FieldType.text,
            contextLevel: 1,
          ),
          FieldDef(
            fieldKey: 'district',
            label: 'District',
            type: FieldType.text,
            contextLevel: 1,
          ),
        ],
      ),
      aTemplate(
        id: 't2',
        projectId: 'p1',
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'country',
            label: 'Country again',
            type: FieldType.text,
            contextLevel: 2,
          ),
        ],
      ),
    ], projectId: 'p1');

    expect(proposal.hasConflicts, isTrue);
    expect(proposal.conflicts, hasLength(1));
    expect(proposal.conflicts.single, contains('country'));
    expect(
      proposal.levels.map(
        (TemplateContextLevelProposal level) => level.field.fieldKey,
      ),
      containsAll(<String>['country', 'district']),
    );
  });

  test('ignores templates owned by another project', () {
    final proposal = TemplateContextProposal.fromTemplates(<TemplateFactory>[
      aTemplate(
        projectId: 'p2',
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'other',
            label: 'Other',
            type: FieldType.text,
            contextLevel: 1,
          ),
        ],
      ),
    ], projectId: 'p1');

    expect(proposal.levels, isEmpty);
    expect(proposal.conflicts, isEmpty);
  });
}
