import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

part 'pdf_page_image.dart';

/// Lazy PDF page rendering. The source file is never modified. Features
/// never call a PDF plugin (FE-STR-11).
abstract interface class PdfPages {
  /// Stub that reads page count from PDF structure without full render.
  factory PdfPages() = _StubPdfPages;

  /// Scripted stand-in for tests.
  factory PdfPages.fake({
    int pageCount = 1,
    Failure? openFailure,
    Uint8List? pageBytes,
  }) {
    return _FakePdfPages(
      pageCount: pageCount,
      openFailure: openFailure,
      pageBytes: pageBytes ?? Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47]),
    );
  }

  /// Opens [bytes] and returns how many pages it reports. Never mutates
  /// [bytes].
  Future<Result<int>> pageCount(Uint8List bytes);

  /// Renders [pageIndex] (0-based) at [longEdge] into cache-ready bytes.
  /// Source [bytes] are never modified.
  Future<Result<PdfPageImage>> renderPage(
    Uint8List bytes, {
    required int pageIndex,
    required int longEdge,
  });
}

/// Process-wide PDF page helper.
final Provider<PdfPages> pdfPagesProvider = Provider<PdfPages>((Ref _) {
  return PdfPages();
});

/// Counts pages from PDF `/Type /Page` markers without a full render.
int countPdfPagesFromStructure(Uint8List bytes) {
  if (bytes.length < 5) {
    return 0;
  }
  // %PDF-
  if (bytes[0] != 0x25 ||
      bytes[1] != 0x50 ||
      bytes[2] != 0x44 ||
      bytes[3] != 0x46) {
    return 0;
  }
  final String text = String.fromCharCodes(bytes);
  final RegExp page = RegExp(r'/Type\s*/Page(?![s\w])');
  final int matches = page.allMatches(text).length;
  if (matches > 0) {
    return matches;
  }
  final Match? countMatch = RegExp(r'/Count\s+(\d+)').firstMatch(text);
  if (countMatch != null) {
    return int.tryParse(countMatch.group(1)!) ?? 1;
  }
  return 1;
}

final class _StubPdfPages implements PdfPages {
  @override
  Future<Result<int>> pageCount(Uint8List bytes) async {
    final int count = countPdfPagesFromStructure(bytes);
    if (count <= 0) {
      return const FailureResult<int>(
        ValidationFailure(
          message: Copy.pdfInvalid,
          recoveryAction: Copy.tryAnotherFile,
        ),
      );
    }
    return Success<int>(count);
  }

  @override
  Future<Result<PdfPageImage>> renderPage(
    Uint8List bytes, {
    required int pageIndex,
    required int longEdge,
  }) async {
    final Result<int> counted = await pageCount(bytes);
    return counted.fold(FailureResult<PdfPageImage>.new, (int total) {
      if (pageIndex < 0 || pageIndex >= total) {
        return const FailureResult<PdfPageImage>(
          ValidationFailure(
            message: Copy.pdfPageMissing,
            recoveryAction: Copy.tryAnotherFile,
          ),
        );
      }
      // No pdf package on the allowlist; emit a placeholder page image so
      // import can proceed without modifying the source.
      final Uint8List placeholder = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        pageIndex & 0xFF,
        longEdge & 0xFF,
      ]);
      return Success<PdfPageImage>(
        PdfPageImage(
          pageIndex: pageIndex,
          bytes: placeholder,
          width: longEdge,
          height: longEdge,
        ),
      );
    });
  }
}

final class _FakePdfPages implements PdfPages {
  _FakePdfPages({
    required int pageCount,
    required this.openFailure,
    required this.pageBytes,
  }) : _pages = pageCount;

  final int _pages;
  final Failure? openFailure;
  final Uint8List pageBytes;

  @override
  Future<Result<int>> pageCount(Uint8List bytes) async {
    final Failure? failure = openFailure;
    if (failure != null) {
      return FailureResult<int>(failure);
    }
    final int fromStructure = countPdfPagesFromStructure(bytes);
    return Success<int>(fromStructure > 0 ? fromStructure : _pages);
  }

  @override
  Future<Result<PdfPageImage>> renderPage(
    Uint8List bytes, {
    required int pageIndex,
    required int longEdge,
  }) async {
    final Result<int> counted = await pageCount(bytes);
    return counted.fold(FailureResult<PdfPageImage>.new, (int total) {
      if (pageIndex < 0 || pageIndex >= total) {
        return const FailureResult<PdfPageImage>(
          ValidationFailure(
            message: Copy.pdfPageMissing,
            recoveryAction: Copy.tryAnotherFile,
          ),
        );
      }
      return Success<PdfPageImage>(
        PdfPageImage(
          pageIndex: pageIndex,
          bytes: Uint8List.fromList(pageBytes),
          width: longEdge,
          height: longEdge,
        ),
      );
    });
  }
}
