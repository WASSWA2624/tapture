import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/templates.dart';

/// In-memory [ShippedTemplateLoader] for widget tests that must not open
/// assets or a database (FE-STATE-10).
final class FakeShippedTemplateLoader implements ShippedTemplateLoader {
  /// Rows [entries] lists. Tests seed this instead of packing JSON.
  final List<ShippedTemplateEntry> catalogue = <ShippedTemplateEntry>[];

  /// Resolved templates [template] and [copyToProject] read, matched to
  /// [catalogue] by key.
  final List<TemplateDef> rows = <TemplateDef>[];

  /// When set, [entries] and [template] return this instead.
  Failure? loadFailure;

  /// When set, [copyToProject] returns this instead of writing.
  Failure? copyFailure;

  /// Copies [copyToProject] wrote, newest last.
  final List<TemplateDef> copies = <TemplateDef>[];

  int _next = 0;

  @override
  Future<Result<List<ShippedTemplateEntry>>> entries() async {
    final Failure? forced = loadFailure;
    if (forced != null) {
      return FailureResult<List<ShippedTemplateEntry>>(forced);
    }
    return Success<List<ShippedTemplateEntry>>(
      List<ShippedTemplateEntry>.of(catalogue),
    );
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
    return const FailureResult<TemplateDef>(_notOnDevice);
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
      return const FailureResult<TemplateDef>(_notOnDevice);
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

const ValidationFailure _notOnDevice = ValidationFailure(
  message: 'That shipped template is not on this device.',
  recoveryAction: 'Pick another template from the library.',
);
