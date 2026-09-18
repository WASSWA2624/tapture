import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/export/export.dart';

import 'feedback_entry.dart';
import 'feedback_filter.dart';
import 'feedback_submitter.dart';

part 'feedback_workbook_columns.dart';

/// A feedback download: the entries a filter kept, laid out the way the
/// organisation's feedback exports already are — one row per entry on
/// `Feedback`, the screenshots on `Screenshots`, and what was asked for on
/// `Export Details`.
///
/// Headers and export values are a file format, not interface copy: they
/// stay the same whatever language the app is shown in, so exports from
/// different devices line up.
final class FeedbackWorkbook {
  /// Creates the download. [entries] are written in the order given.
  /// [utcOffset] turns stored UTC times into the wall clock of [timeZone].
  const FeedbackWorkbook({
    required this.entries,
    required this.filter,
    required this.generatedAtUtc,
    required this.utcOffset,
    required this.timeZone,
    required this.generatedBy,
    this.screenshots = const <String, Uint8List>{},
  });

  /// The rows, in order.
  final List<FeedbackEntry> entries;

  /// Screenshot PNGs by entry id. An entry missing here has none.
  final Map<String, Uint8List> screenshots;

  /// What was asked for, echoed on the details sheet.
  final FeedbackFilter filter;

  /// When the download was made.
  final DateTime generatedAtUtc;

  /// The downloading device's offset from UTC.
  final Duration utcOffset;

  /// The downloading device's zone name, used in the local-time header.
  final String timeZone;

  /// Who asked for the download.
  final String generatedBy;

  /// `TAPTURE-18092026-1002.xlsx`: day, month and year, then the 24-hour
  /// time, on the downloading device's clock.
  String get fileName {
    final DateTime at = _wall(generatedAtUtc);
    final String date =
        '${_two(at.day)}${_two(at.month)}${at.year.toString().padLeft(4, '0')}';
    return '$_filePrefix-$date-${_two(at.hour)}${_two(at.minute)}.xlsx';
  }

  /// The workbook, ready for [XlsxEncoder].
  XlsxBook toBook() {
    final List<FeedbackEntry> pictured = <FeedbackEntry>[
      for (final FeedbackEntry entry in entries)
        if (_picture(entry) != null) entry,
    ];
    return XlsxBook(
      createdUtc: generatedAtUtc,
      subject: _subject,
      sheets: <XlsxSheet>[
        _feedbackSheet(pictured),
        if (pictured.isNotEmpty) _screenshotSheet(pictured),
        _detailsSheet(pictured.length),
      ],
    );
  }

  /// The encoded file. Top-level so the isolate runner can call it
  /// (FE-PERF-02).
  static Uint8List encode(FeedbackWorkbook workbook) {
    return XlsxEncoder.encode(workbook.toBook());
  }

  XlsxSheet _feedbackSheet(List<FeedbackEntry> pictured) {
    final List<_Column> columns = _columns(localHeader: _localHeader);
    final Map<String, int> screenshotRows = <String, int>{
      for (int index = 0; index < pictured.length; index++)
        pictured[index].id: index + 1,
    };
    return XlsxSheet(
      name: _feedbackSheetName,
      freezeHeader: true,
      autoFilter: true,
      columns: <XlsxColumn>[for (final _Column column in columns) column.spec],
      rows: <List<XlsxCell>>[
        for (final FeedbackEntry entry in entries)
          <XlsxCell>[
            for (final _Column column in columns)
              column.cell(
                entry,
                _Row(
                  local: _wall(entry.submittedAtUtc),
                  screenshotRow: screenshotRows[entry.id],
                ),
              ),
          ],
      ],
    );
  }

  XlsxSheet _screenshotSheet(List<FeedbackEntry> pictured) {
    final List<XlsxImage> images = <XlsxImage>[];
    final Map<int, double> heights = <int, double>{};
    for (int index = 0; index < pictured.length; index++) {
      final FeedbackEntry entry = pictured[index];
      final Uint8List png = _picture(entry)!;
      final ({int width, int height}) size = XlsxImage.fitWithin(
        png,
        AppConstants.userFeedback.workbookImageEdge,
      )!;
      images.add(
        XlsxImage(
          row: index + 1,
          column: _imageColumn,
          png: png,
          width: size.width,
          height: size.height,
        ),
      );
      heights[index + 1] = size.height * _pointsPerPixel + _imagePadding;
    }
    return XlsxSheet(
      name: _screenshotSheetName,
      freezeHeader: true,
      columns: <XlsxColumn>[
        const XlsxColumn(_idHeader),
        XlsxColumn(_localHeader, width: _dateWidth),
        const XlsxColumn(_screenHeader, width: _screenWidth),
        const XlsxColumn(_screenshotHeader, width: _imageWidth),
      ],
      rows: <List<XlsxCell>>[
        for (final FeedbackEntry entry in pictured)
          <XlsxCell>[
            XlsxCell.text(entry.reference),
            XlsxCell.dateTime(_wall(entry.submittedAtUtc)),
            XlsxCell.textOrEmpty(entry.context.screen),
          ],
      ],
      images: images,
      rowHeights: heights,
    );
  }

  XlsxSheet _detailsSheet(int pictures) {
    XlsxCell bound(DateTime? at) {
      return at == null
          ? const XlsxCell.text(_anyTime)
          : XlsxCell.dateTime(_wall(at));
    }

    return XlsxSheet(
      name: _detailsSheetName,
      columns: const <XlsxColumn>[
        XlsxColumn('Detail', width: 24),
        XlsxColumn('Value', width: 60),
      ],
      rows: <List<XlsxCell>>[
        _detail('Generated At', XlsxCell.dateTime(_wall(generatedAtUtc))),
        _detail('Time Zone', XlsxCell.text(timeZone)),
        _detail('Generated By', XlsxCell.text(generatedBy)),
        _detail('Records', XlsxCell.number(entries.length)),
        _detail('Screenshots', XlsxCell.number(pictures)),
        _detail(
          'Category',
          _facet(filter.categories.map((c) => c.exportLabel)),
        ),
        _detail(
          'Submitted By',
          _facet(filter.submitters.map((FeedbackSubmitter s) => s.exportLabel)),
        ),
        _detail(
          'Device Type',
          _facet(filter.deviceTypes.map((d) => d.exportLabel)),
        ),
        _detail('Platform', _facet(filter.platforms)),
        _detail('Screen', _facet(filter.screens)),
        _detail('Screenshot', XlsxCell.text(filter.screenshot.exportLabel)),
        _detail(
          'Search',
          XlsxCell.text(filter.search.trim().isEmpty ? _none : filter.search),
        ),
        _detail('Submitted From', bound(filter.fromUtc)),
        _detail('Submitted To', bound(filter.toUtc)),
      ],
    );
  }

  Uint8List? _picture(FeedbackEntry entry) {
    final Uint8List? png = entry.hasScreenshot ? screenshots[entry.id] : null;
    if (png == null || XlsxImage.pngSize(png) == null) {
      return null;
    }
    return png;
  }

  String get _localHeader => 'Submitted At ($timeZone)';

  /// [utc] on the downloading device's wall clock.
  DateTime _wall(DateTime utc) => utc.toUtc().add(utcOffset);
}

List<XlsxCell> _detail(String name, XlsxCell value) {
  return <XlsxCell>[XlsxCell.text(name), value];
}

XlsxCell _facet(Iterable<String> chosen) {
  final List<String> values = chosen.toList()..sort();
  return XlsxCell.text(values.isEmpty ? _all : values.join(', '));
}

String _two(int value) => value.toString().padLeft(2, '0');

const String _filePrefix = 'TAPTURE';
const String _subject = 'Feedback export';
const String _feedbackSheetName = 'Feedback';
const String _screenshotSheetName = 'Screenshots';
const String _detailsSheetName = 'Export Details';
const String _all = 'All';
const String _none = 'None';
const String _anyTime = 'Any time';

/// Zero-based column the picture sits in on the screenshot sheet.
const int _imageColumn = 3;

/// A picture's width in character units: 480 pixels at about seven each.
const double _imageWidth = 70;

/// Row height is in points; there are three points to four pixels.
const double _pointsPerPixel = 0.75;

/// Space under a picture so the next row's does not touch it, in points.
const double _imagePadding = 8;
