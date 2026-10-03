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
  /// Creates the summary. [estimatedBytes] is the package's expected size,
  /// when known. [destination] is the short folder label where
  /// the file is copied, or null where the platform decides.
  const ExportSummaryView({
    required this.summary,
    required this.destination,
    this.estimatedBytes,
    super.key,
  });

  /// Counts and names from the export repository.
  final ExportSummary summary;

  /// Downloads folder label, without the Exports subfolder.
  final String? destination;

  /// The package's expected size, shown before it is written.
  final int? estimatedBytes;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String locale = Localizations.localeOf(context).toString();
    final DateTime? first = summary.firstCapturedAt;
    final DateTime? last = summary.lastCapturedAt;
    final String? place = destination;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: localCopy.exportSectionProject),
        Text(
          summary.projectName,
          style: AppText.title.copyWith(color: context.colors.onSurface),
        ),
        const SizedBox(height: Space.x2),
        _row(AppIcons.records, localCopy.recordsCount(summary.records)),
        _row(
          AppIcons.photoLibrary,
          localCopy.capturePhotoCount(summary.photos),
        ),
        if (summary.audioClips > 0)
          _row(
            AppIcons.recordAudio,
            localCopy.exportAudioClips(summary.audioClips),
          ),
        if (first != null && last != null)
          _row(
            AppIcons.history,
            localCopy.exportCapturedBetween(
              DateFormat.yMMMd(locale).format(first.toLocal()),
              DateFormat.yMMMd(locale).format(last.toLocal()),
            ),
          ),
        const SizedBox(height: Space.x4),
        AppSectionHeader(title: localCopy.exportSectionRecords),
        _row(
          AppIcons.queued,
          localCopy.exportUnprocessedCount(summary.unprocessed),
        ),
        _row(
          AppIcons.review,
          localCopy.exportNeedsReviewCount(summary.needsReview),
        ),
        _row(
          AppIcons.verified,
          localCopy.exportApprovedCount(summary.approved),
        ),
        if (summary.templates.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x4),
          AppSectionHeader(title: localCopy.exportSectionTemplates),
          for (final ExportTemplateCount template in summary.templates)
            AppListTile(
              title: template.name,
              subtitle: localCopy.recordsCount(template.records),
              leading: const Icon(AppIcons.template),
              dense: true,
            ),
        ],
        const SizedBox(height: Space.x4),
        AppSectionHeader(title: localCopy.exportSectionFile),
        _row(AppIcons.export, localCopy.exportFileFormat),
        _row(AppIcons.columns, localCopy.exportFileColumns),
        if (estimatedBytes case final int bytes)
          _row(AppIcons.save, localCopy.exportPackageSize(bytes)),
        if (place != null)
          _row(AppIcons.folder, localCopy.exportSavedTo(place)),
      ],
    );
  }

  Widget _row(IconData icon, String text) {
    return AppListTile(title: text, leading: Icon(icon), dense: true);
  }
}
