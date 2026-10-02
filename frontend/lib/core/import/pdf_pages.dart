import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;
import 'package:pdfrx/pdfrx.dart' as pdf;
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

part 'pdf_page_image.dart';
part 'pdf_pages_renderer.dart';

/// Lazy PDF page rendering. The source file is never modified. Features
/// never call a PDF plugin (FE-STR-11).
abstract interface class PdfPages {
  /// Real PDFium/PDF.js parsing and lazy rasterization.
  factory PdfPages() = _RenderedPdfPages;

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

  /// Releases the open document and its native/browser worker resources.
  Future<void> dispose();

  /// Releases [bytes] only if they still own the renderer's open document.
  Future<void> release(Uint8List bytes);
}

/// Process-wide PDF page helper.
final Provider<PdfPages> pdfPagesProvider = Provider<PdfPages>((Ref ref) {
  final _RenderedPdfPages pages = _RenderedPdfPages();
  ref.onDispose(() => unawaited(pages.dispose()));
  return pages;
});

/// Native-resource observation for lifecycle regression tests.
@visibleForTesting
bool debugPdfHasOpenDocument(PdfPages pages) =>
    pages is _RenderedPdfPages && pages._document != null;

/// Makes a standard JPEG photo from a rendered PDF page off the UI isolate.
Future<Result<Uint8List>> pdfPageAsPhoto(Uint8List png) =>
    runIsolate(_encodePdfPhoto, png);

Uint8List _encodePdfPhoto(Uint8List png) {
  final image.Image? page = image.decodePng(png);
  if (page == null) {
    throw ValidationFailure(localizedMessage: Copy.messages.pdfInvalid);
  }
  return Uint8List.fromList(
    image.encodeJpg(page, quality: AppConstants.images.quality),
  );
}

/// Validates a cached page off the UI isolate before using its dimensions.
Future<Result<PdfPageImage>> cachedPdfPage(Uint8List png, int index) =>
    runIsolate(_decodeCachedPdfPage, (bytes: png, index: index));

PdfPageImage _decodeCachedPdfPage(({Uint8List bytes, int index}) input) {
  final image.Image? page = image.decodePng(input.bytes);
  if (page == null ||
      max(page.width, page.height) > AppConstants.images.longEdge) {
    throw const CorruptionFailure();
  }
  return PdfPageImage(
    pageIndex: input.index,
    bytes: input.bytes,
    width: page.width,
    height: page.height,
  );
}

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
  Future<void> dispose() async {}

  @override
  Future<void> release(Uint8List bytes) async {}

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
        return FailureResult<PdfPageImage>(
          ValidationFailure(
            localizedMessage: Copy.messages.pdfPageMissing,
            localizedRecovery: Copy.messages.tryAnotherFile,
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
