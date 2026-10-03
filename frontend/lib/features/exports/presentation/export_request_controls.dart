import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/show_app_text_prompt.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/features/merge/merge.dart'
    show BundleScopeKind, BundleScopeSection;

import '../exports.dart' show ExportRepository, exportRepositoryProvider;
import 'export_options_section.dart';
import 'export_scope_section.dart';
import 'export_workflow.dart';
import 'export_workflow_controller.dart';

/// The same request controls compose a new export and remembered choices.
final class ExportRequestControls extends ConsumerWidget {
  const ExportRequestControls({
    required this.projectId,
    required this.workflow,
    required this.count,
    super.key,
  });

  final String projectId;
  final ExportWorkflow workflow;
  final int? count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ExportRequest request = workflow.request;
    final ExportWorkflowController controller = ref.read(
      exportWorkflowControllerProvider(projectId).notifier,
    );
    void change(ExportRequest request) => unawaited(controller.change(request));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppChoiceField<bool>(
          label: localCopy.exportOutput,
          options: <Choice<bool>>[
            Choice<bool>(true, localCopy.exportFileFormat),
            Choice<bool>(false, localCopy.exportOutputFiles),
          ],
          value: request.isProjectPackage,
          onChanged: (bool? package) => change(
            request.copyWith(
              formats: package == true
                  ? const <ExportFormat>{ExportFormat.zip}
                  : const <ExportFormat>{ExportFormat.xlsx},
            ),
          ),
        ),
        if (request.isProjectPackage) ...<Widget>[
          AsyncValueView<int>(
            value: ref.watch(
              _packageEstimateProvider((
                request: request,
                withoutPhotos: workflow.withoutPhotos,
              )),
            ),
            data: (int bytes) => BundleScopeSection(
              selected: _bundleScope(workflow),
              sizeLabel: Copy.of(context).fileSize(bytes),
              onSelect: (BundleScopeKind scope) =>
                  unawaited(controller.bundleScope(scope)),
            ),
          ),
          if (request.scope.kind == ExportScopeKind.dateRange)
            ..._dates(request, change, localizedCopy: Copy.of(context)),
          AppButton(
            label: workflow.password?.isNotEmpty == true
                ? localCopy.bundlePasswordSet
                : localCopy.bundlePasswordOptional,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final LocalizedCopy localCopy = Copy.of(context);

              final String? password = await showAppTextPrompt(
                context,
                title: localCopy.bundlePasswordOptional,
                label: localCopy.bundlePassword,
                obscureText: true,
                validate: (_) async => const Success<void>(null),
              );
              if (password != null) controller.password(password);
            },
          ),
          if (count != null) Text(localCopy.exportCount(count!)),
        ] else ...<Widget>[
          for (final ExportFormat format in ExportFormat.values)
            if (format != ExportFormat.zip)
              AppSwitchTile(
                key: ValueKey<String>('export-format-${format.name}'),
                title: _label(format, localizedCopy: Copy.of(context)),
                value: request.formats.contains(format),
                onChanged: (bool enabled) => change(
                  request.copyWith(
                    formats: enabled
                        ? <ExportFormat>{...request.formats, format}
                        : (<ExportFormat>{...request.formats}..remove(format)),
                  ),
                ),
              ),
          ExportScopeSection(
            selected: request.scope.kind,
            count: count,
            onSelect: (ExportScopeKind kind) =>
                unawaited(controller.scope(kind)),
          ),
          if (request.scope.kind == ExportScopeKind.dateRange)
            ..._dates(request, change, localizedCopy: Copy.of(context)),
          ExportOptionsSection(
            columns: request.columns,
            advancedOpen: workflow.advanced,
            onToggleAdvanced: controller.toggleAdvanced,
            onChanged: (ExportColumns columns) =>
                change(request.copyWith(columns: columns)),
          ),
          if (workflow.advanced) ...<Widget>[
            AppSwitchTile(
              title: localCopy.exportDictionary,
              value: request.extras.dictionary,
              onChanged: (bool dictionary) => change(
                request.copyWith(
                  extras: (
                    dictionary: dictionary,
                    photoIndex: request.extras.photoIndex,
                    photoMode: request.extras.photoMode,
                    pdfPhotos: request.extras.pdfPhotos,
                    delimiter: request.extras.delimiter,
                  ),
                ),
              ),
            ),
            AppChoiceField<String>(
              label: localCopy.exportPhotoMode,
              options: <Choice<String>>[
                Choice<String>('filename', localCopy.exportPhotoFilename),
                Choice<String>('relative', localCopy.exportPhotoRelative),
                Choice<String>('embed', localCopy.exportPhotoEmbed),
              ],
              value: request.extras.photoMode,
              onChanged: (String? value) => change(
                request.copyWith(
                  extras: (
                    dictionary: request.extras.dictionary,
                    photoIndex: request.extras.photoIndex,
                    photoMode: value ?? request.extras.photoMode,
                    pdfPhotos: request.extras.pdfPhotos,
                    delimiter: request.extras.delimiter,
                  ),
                ),
              ),
            ),
            AppChoiceField<String>(
              label: localCopy.exportPdfPhotos,
              options: <Choice<String>>[
                Choice<String>(
                  PdfPhotoLayout.thumbnail,
                  localCopy.exportPdfThumbnails,
                ),
                Choice<String>(PdfPhotoLayout.full, localCopy.exportPdfFull),
              ],
              value: request.extras.pdfPhotos,
              onChanged: (String? value) => change(
                request.copyWith(
                  extras: (
                    dictionary: request.extras.dictionary,
                    photoIndex: request.extras.photoIndex,
                    photoMode: request.extras.photoMode,
                    pdfPhotos: value ?? request.extras.pdfPhotos,
                    delimiter: request.extras.delimiter,
                  ),
                ),
              ),
            ),
            AppChoiceField<String>(
              label: localCopy.exportDelimiter,
              options: <Choice<String>>[
                Choice<String>(',', localCopy.exportDelimiterComma),
                Choice<String>(';', localCopy.exportDelimiterSemicolon),
                Choice<String>('\t', localCopy.exportDelimiterTab),
              ],
              value: request.extras.delimiter,
              onChanged: (String? value) => change(
                request.copyWith(
                  extras: (
                    dictionary: request.extras.dictionary,
                    photoIndex: request.extras.photoIndex,
                    photoMode: request.extras.photoMode,
                    pdfPhotos: request.extras.pdfPhotos,
                    delimiter: value ?? request.extras.delimiter,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

String _label(ExportFormat format, {LocalizedCopy? localizedCopy}) =>
    switch (format) {
      ExportFormat.xlsx => (localizedCopy ?? Copy.english).exportFormatXlsx,
      ExportFormat.csv => (localizedCopy ?? Copy.english).exportFormatCsv,
      ExportFormat.json => (localizedCopy ?? Copy.english).exportFormatJson,
      ExportFormat.pdf => (localizedCopy ?? Copy.english).exportFormatPdf,
      ExportFormat.zip => (localizedCopy ?? Copy.english).exportFileFormat,
    };

final _packageEstimateProvider = FutureProvider.autoDispose
    .family<int, ({ExportRequest request, bool withoutPhotos})>((
      Ref ref,
      ({ExportRequest request, bool withoutPhotos}) selection,
    ) async {
      final ExportRepository? store = ref.watch(exportRepositoryProvider);
      return store == null
          ? 0
          : (await store.estimatePackage(
              selection.request.projectId,
              scope: selection.request.scope,
              withoutPhotos: selection.withoutPhotos,
            )).getOrThrow();
    });

BundleScopeKind _bundleScope(ExportWorkflow workflow) => workflow.withoutPhotos
    ? BundleScopeKind.withoutPhotos
    : switch (workflow.request.scope.kind) {
        ExportScopeKind.all || ExportScopeKind.filter => BundleScopeKind.full,
        ExportScopeKind.approved => BundleScopeKind.approved,
        ExportScopeKind.context => BundleScopeKind.context,
        ExportScopeKind.dateRange => BundleScopeKind.dateRange,
      };

List<Widget> _dates(
  ExportRequest request,
  void Function(ExportRequest) change, {
  LocalizedCopy? localizedCopy,
}) => <Widget>[
  AppDateField(
    label: (localizedCopy ?? Copy.english).exportScopeFrom,
    value: DateTime.tryParse(request.scope.from ?? ''),
    onChanged: (DateTime? value) => change(
      request.copyWith(
        scope: (
          kind: request.scope.kind,
          context: request.scope.context,
          from: value?.toUtc().toIso8601String(),
          to: request.scope.to,
          filter: request.scope.filter,
        ),
      ),
    ),
  ),
  AppDateField(
    label: (localizedCopy ?? Copy.english).exportScopeTo,
    value: DateTime.tryParse(request.scope.to ?? ''),
    onChanged: (DateTime? value) => change(
      request.copyWith(
        scope: (
          kind: request.scope.kind,
          context: request.scope.context,
          from: request.scope.from,
          to: value == null
              ? null
              : DateTime.fromMicrosecondsSinceEpoch(
                  DateTime(
                        value.year,
                        value.month,
                        value.day + 1,
                      ).toUtc().microsecondsSinceEpoch -
                      1,
                  isUtc: true,
                ).toIso8601String(),
          filter: request.scope.filter,
        ),
      ),
    ),
  ),
];
