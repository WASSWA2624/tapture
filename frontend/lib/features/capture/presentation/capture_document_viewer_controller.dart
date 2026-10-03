import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/import/pdf_pages.dart';

import '../domain/document_draft.dart';

/// Keeps page navigation and durable addition outside the viewer widget.
final class CaptureDocumentViewerController
    extends Notifier<CaptureDocumentViewState> {
  /// Uses stable attachment metadata for navigation bounds.
  CaptureDocumentViewerController(this.document);
  final DocumentDraft document;

  @override
  CaptureDocumentViewState build() => (index: 0, adding: false);

  /// Moves to an existing page while no addition is pending.
  void move(int index) {
    if (!state.adding && index >= 0 && index < (document.pageCount ?? 0)) {
      state = (index: index, adding: false);
    }
  }

  /// Normalizes and persists a page before the UI confirms it.
  Future<Result<void>> add(
    PdfPageImage page,
    Future<Result<void>> Function(Uint8List) persist,
  ) async {
    if (state.adding) return const Success<void>(null);
    state = (index: state.index, adding: true);
    final Result<void> result = await Result.captureAsync(() async {
      final Uint8List bytes = (await pdfPageAsPhoto(page.bytes)).getOrThrow();
      (await persist(bytes)).getOrThrow();
    });
    if (ref.mounted) state = (index: state.index, adding: false);
    return result;
  }
}

/// The visible page and whether its evidence addition is pending.
typedef CaptureDocumentViewState = ({int index, bool adding});

/// View state is released when the attachment closes.
final captureDocumentViewerControllerProvider = NotifierProvider.autoDispose
    .family<
      CaptureDocumentViewerController,
      CaptureDocumentViewState,
      DocumentDraft
    >(CaptureDocumentViewerController.new);

/// Reads an original only when a requested page has no valid cached derivative.
final captureDocumentSourceProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((Ref ref, String path) async {
      final FileReader reader = ref.watch(fileReaderProvider);
      final PdfPages pages = ref.watch(pdfPagesProvider);
      final Uint8List source = (await reader.read(path)).getOrThrow();
      if (!ref.mounted) {
        await pages.release(source);
        throw const CancelledFailure();
      }
      ref.onDispose(() => unawaited(pages.release(source)));
      return source;
    });

/// A page is independently disposable; one source is shared during navigation.
final captureDocumentPageProvider = FutureProvider.autoDispose
    .family<PdfPageImage, ({String path, String sha, int index})>((
      Ref ref,
      ({String path, String sha, int index}) request,
    ) async {
      final FileReader reader = ref.watch(fileReaderProvider);
      final FileWriter writer = ref.watch(fileWriterProvider);
      final PdfPages pages = ref.watch(pdfPagesProvider);
      final String cache =
          '.cache/document-pages/${request.sha}/${request.index}.png';
      final Result<Uint8List> cached = await reader.read(cache);
      if (cached case Success<Uint8List>(:final Uint8List value)) {
        final Result<PdfPageImage> decoded = await cachedPdfPage(
          value,
          request.index,
        );
        if (decoded case Success<PdfPageImage>(:final PdfPageImage value)) {
          return value;
        }
      }
      if (!ref.mounted) throw const CancelledFailure();
      final Uint8List source = await ref.watch(
        captureDocumentSourceProvider(request.path).future,
      );
      if (!ref.mounted) throw const CancelledFailure();
      final PdfPageImage page = (await pages.renderPage(
        source,
        pageIndex: request.index,
        longEdge: AppConstants.images.longEdge,
      )).getOrThrow();
      if (!ref.mounted) throw const CancelledFailure();
      (await writer.write(
        Stream<List<int>>.value(page.bytes),
        cache,
      )).getOrThrow();
      return page;
    });
