import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/features/exports/exports.dart';

/// What a project export holds: the project, its records by status, the
/// templates they use and the file it writes (FBK0000134).
class ExportSummaryView extends StatelessWidget {
  /// Creates the summary. [destination] is the short folder label where
  /// the file is copied, or null where the platform decides.
  const ExportSummaryView({
    required this.summary,
    required this.destination,
    super.key,
  });

  /// Counts and names from the export repository.
  final ExportSummary summary;

  /// Downloads folder label, without the Exports subfolder.
  final String? destination;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    final DateTime? first = summary.firstCapturedAt;
    final DateTime? last = summary.lastCapturedAt;
    final String? place = destination;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.exportSectionProject),
        Text(
          summary.projectName,
          style: AppText.title.copyWith(color: context.colors.onSurface),
        ),
        const SizedBox(height: Space.x2),
        _row(AppIcons.records, Copy.recordsCount(summary.records)),
        _row(AppIcons.photoLibrary, Copy.capturePhotoCount(summary.photos)),
        if (summary.audioClips > 0)
          _row(AppIcons.recordAudio, Copy.exportAudioClips(summary.audioClips)),
        if (first != null && last != null)
          _row(
            AppIcons.history,
            Copy.exportCapturedBetween(
              DateFormat.yMMMd(locale).format(first.toLocal()),
              DateFormat.yMMMd(locale).format(last.toLocal()),
            ),
          ),
        const SizedBox(height: Space.x4),
        const AppSectionHeader(title: Copy.exportSectionRecords),
        _row(AppIcons.queued, Copy.exportUnprocessedCount(summary.unprocessed)),
        _row(AppIcons.review, Copy.exportNeedsReviewCount(summary.needsReview)),
        _row(AppIcons.verified, Copy.exportApprovedCount(summary.approved)),
        if (summary.templates.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x4),
          const AppSectionHeader(title: Copy.exportSectionTemplates),
          for (final ExportTemplateCount template in summary.templates)
            AppListTile(
              title: template.name,
              subtitle: Copy.recordsCount(template.records),
              leading: const Icon(AppIcons.template),
              dense: true,
            ),
        ],
        const SizedBox(height: Space.x4),
        const AppSectionHeader(title: Copy.exportSectionFile),
        _row(AppIcons.export, Copy.exportFileFormat),
        _row(AppIcons.columns, Copy.exportFileColumns),
        if (place != null) _row(AppIcons.folder, Copy.exportSavedTo(place)),
      ],
    );
  }

  Widget _row(IconData icon, String text) {
    return AppListTile(title: text, leading: Icon(icon), dense: true);
  }
}
