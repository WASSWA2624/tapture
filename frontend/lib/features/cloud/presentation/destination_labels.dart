import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/copy/copy.dart';

import '../domain/destination_check.dart';

/// The plain name of [kind].
String destinationKindLabel(DestinationKind kind, {LocalizedCopy? copy}) {
  final LocalizedCopy localized = copy ?? Copy.english;
  return switch (kind) {
    DestinationKind.s3 => localized.destinationKindS3,
    DestinationKind.googleDrive => localized.destinationKindDrive,
    DestinationKind.oneDrive => localized.destinationKindOneDrive,
    DestinationKind.dropbox => localized.destinationKindDropbox,
    DestinationKind.webdav => localized.destinationKindWebDav,
    DestinationKind.localFolder => localized.destinationKindLocal,
  };
}

/// The remote folder as the confirmation sheet names it.
String destinationFolderLabel(String folder, {LocalizedCopy? copy}) {
  final LocalizedCopy localized = copy ?? Copy.english;
  final String trimmed = folder.trim();
  return trimmed.isEmpty ? localized.destinationFolderRoot : trimmed;
}

/// One row line: kind, folder and the outcome of the last connection check.
String destinationSummary(
  Destination destination, {
  bool checking = false,
  LocalizedCopy? copy,
}) {
  final LocalizedCopy localized = copy ?? Copy.english;
  final String base =
      '${destinationKindLabel(destination.kind, copy: localized)} · '
      '${destinationFolderLabel(destination.folder, copy: localized)}';
  if (checking) {
    return '$base · ${localized.destinationChecking}';
  }
  final DestinationCheck? check = DestinationCheck.decode(
    destination.lastCheck,
  );
  if (check == null) {
    return base;
  }
  final String? reason = check.localizedReason == null
      ? check.reason
      : localized.resolve(check.localizedReason!);
  return reason == null
      ? '$base · ${localized.destinationCheckedAt(check.at)}'
      : '$base · ${localized.destinationCheckFailedAt(reason)}';
}
