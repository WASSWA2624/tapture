import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Files hung on a meeting: agendas, reports, handouts and photos.
final class MeetingAttachments extends StatelessWidget {
  /// Creates the list. An empty [files] list is the empty state.
  const MeetingAttachments({
    this.files = const <MeetingFile>[],
    this.failure,
    this.onAdd,
    this.onOpen,
    super.key,
  });

  /// Attachments in list order.
  final List<MeetingFile> files;

  /// Why the list could not be read.
  final Failure? failure;

  /// Picks another file or photo.
  final VoidCallback? onAdd;

  /// Opens the attachment [id].
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (files.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.import,
        headline: Copy.meetingAttachmentsEmpty,
        message: Copy.meetingAttachmentsEmptyMessage,
        actionLabel: Copy.meetingAddAttachment,
        onAction: onAdd,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MeetingFile file in files)
          AppCard(
            child: AppListTile(
              key: ValueKey<String>('attachment-${file.id}'),
              title: file.name,
              subtitle: '${file.kind} · ${file.bytes} B',
              onTap: onOpen == null ? null : () => onOpen!(file.id),
            ),
          ),
        AppButton(
          key: const ValueKey<String>('attachment-add'),
          label: Copy.meetingAddAttachment,
          variant: AppButtonVariant.secondary,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

/// One file on the meeting. [kind] and [name] are meeting content.
typedef MeetingFile = ({String id, String name, String kind, int bytes});
