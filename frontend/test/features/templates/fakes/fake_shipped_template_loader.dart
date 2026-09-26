import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/templates.dart';

/// In-memory [ShippedTemplateLoader] for widget tests that must not open
/// assets or a database (FE-STATE-10).
final class FakeShippedTemplateLoader implements ShippedTemplateLoader {
  /// Templates [library] returns. Tests seed this instead of packing JSON.
  final List<TemplateDef> rows = <TemplateDef>[];

  /// Catalogue rows [entries] lists after [rows]. Each resolves to the
  /// [rows] template with the same key, so seed both for a preview or copy.
  final List<ShippedTemplateEntry> catalogue = <ShippedTemplateEntry>[];

  /// When set, [library] returns this instead of [rows].
  Failure? loadFailure;

  /// When set, [copyToProject] returns this instead of writing.
  Failure? copyFailure;

  /// Copies [copyToProject] wrote, newest last.
  final List<TemplateDef> copies = <TemplateDef>[];

  int _next = 0;

  @override
  Future<Result<List<TemplateDef>>> library() async {
    final Failure? forced = loadFailure;
    if (forced != null) {
      return FailureResult<List<TemplateDef>>(forced);
    }
    return Success<List<TemplateDef>>(List<TemplateDef>.of(rows));
  }

  @override
  Future<Result<List<ShippedTemplateEntry>>> entries() async {
    final Failure? forced = loadFailure;
    if (forced != null) {
      return FailureResult<List<ShippedTemplateEntry>>(forced);
    }
    final Set<String> listed = <String>{
      for (final ShippedTemplateEntry entry in catalogue) entry.templateKey,
    };
    return Success<List<ShippedTemplateEntry>>(<ShippedTemplateEntry>[
      for (final TemplateDef row in rows)
        if (!listed.contains(row.templateKey))
          ShippedTemplateEntry.starter(row),
      ...catalogue,
    ]);
  }

  @override
  Future<Result<TemplateDef>> template(String templateKey) async {
    final Failure? forced = loadFailure;
    if (forced != null) {
      return FailureResult<TemplateDef>(forced);
    }
    for (final TemplateDef row in rows) {
      if (row.templateKey == templateKey) {
        return Success<TemplateDef>(row);
      }
    }
    return const FailureResult<TemplateDef>(
      ValidationFailure(
        message: 'That shipped template is not on this device.',
        recoveryAction: 'Pick another template from the library.',
      ),
    );
  }

  @override
  Future<Result<TemplateDef>> copyToProject({
    required String templateKey,
    required String projectId,
    required String name,
  }) async {
    final Failure? forced = copyFailure;
    if (forced != null) {
      return FailureResult<TemplateDef>(forced);
    }
    TemplateDef? source;
    for (final TemplateDef row in rows) {
      if (row.templateKey == templateKey) {
        source = row;
        break;
      }
    }
    if (source == null) {
      return const FailureResult<TemplateDef>(
        ValidationFailure(
          message: 'That shipped template is not on this device.',
          recoveryAction: 'Pick another template from the library.',
        ),
      );
    }
    final TemplateDef stored = source.copyWith(
      id: 'template-${_next++}',
      name: name,
      version: 1,
      projectId: projectId,
      source: 'shipped',
      fields: List<FieldDef>.of(source.fields),
      identityFieldKeys: List<String>.of(source.identityFieldKeys),
      rows: List<TemplateRow>.of(source.rows),
    );
    copies.add(stored);
    return Success<TemplateDef>(stored);
  }
}
