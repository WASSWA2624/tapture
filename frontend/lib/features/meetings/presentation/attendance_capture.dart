import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import '../domain/attendance_reading.dart';

/// Photographs a signed sheet, then lets each row be edited before it joins
/// the attendee list. Nothing is added until [onAccept].
final class AttendanceCapture extends StatelessWidget {
  /// Creates the capture. No photo and no rows is the empty state.
  const AttendanceCapture({
    this.photoPath,
    this.readings = const <AttendanceReading>[],
    this.failure,
    this.onCapture,
    this.onChanged,
    this.onAccept,
    this.onAddRow,
    super.key,
  });

  /// The sheet photo. It stays even when [readings] is empty.
  final String? photoPath;

  /// Rows read from the sheet, still editable.
  final List<AttendanceReading> readings;

  /// Why the sheet could not be opened.
  final Failure? failure;

  /// Opens the shutter. The photo is typed attendance.
  final VoidCallback? onCapture;

  /// Replaces the rows after an edit.
  final ValueChanged<List<AttendanceReading>>? onChanged;

  /// Adds the edited rows to the attendee list.
  final VoidCallback? onAccept;

  /// Adds a blank row when the reading is poor.
  final VoidCallback? onAddRow;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (photoPath == null && readings.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.camera,
        headline: localCopy.meetingSheetEmpty,
        message: localCopy.meetingSheetEmptyMessage,
        actionLabel: localCopy.meetingPhotographSheet,
        onAction: onCapture,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (photoPath != null)
          AppCard(
            key: const ValueKey<String>('attendance-photo'),
            child: Text('${localCopy.photoAttendance} · $photoPath'),
          ),
        if (photoPath != null && readings.isEmpty)
          Text(localCopy.meetingSheetKept),
        for (var index = 0; index < readings.length; index++)
          _row(context, readings[index], index),
        AppButton(
          key: const ValueKey<String>('attendance-add-row'),
          label: localCopy.meetingAddAttendee,
          variant: AppButtonVariant.secondary,
          onPressed: onAddRow,
        ),
        AppButton(
          key: const ValueKey<String>('attendance-accept'),
          label: localCopy.meetingAcceptRows,
          onPressed: readings.isEmpty ? null : onAccept,
        ),
      ],
    );
  }

  Widget _row(BuildContext context, AttendanceReading reading, int index) {
    return AppCard(
      key: ValueKey<String>('attendance-row-$index'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            key: ValueKey<String>('attendance-name-$index'),
            label: Copy.of(context).meetingAttendeeName,
            controller: TextEditingController(text: reading.name),
            onChanged: (String text) =>
                _replace(index, reading.copyWith(name: text)),
          ),
          Text('${reading.nameConfidence}'),
        ],
      ),
    );
  }

  void _replace(int index, AttendanceReading next) {
    onChanged?.call(<AttendanceReading>[
      for (var i = 0; i < readings.length; i++)
        if (i == index) next else readings[i],
    ]);
  }
}
