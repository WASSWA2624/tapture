part of 'pdf_pages.dart';

final class _RenderedPdfPages implements PdfPages {
  pdf.PdfDocument? _document;
  Uint8List? _source;
  Future<void> _pending = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final Future<T> result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<pdf.PdfDocument> _open(Uint8List bytes) async {
    if (identical(_source, bytes) && _document != null) return _document!;
    await _document?.dispose();
    _source = null;
    _document = null;
    try {
      final pdf.PdfDocument document = await pdf.PdfDocument.openData(bytes);
      if (document.pages.isEmpty) {
        await document.dispose();
        throw _invalid();
      }
      _document = document;
      _source = bytes;
      return document;
    } on Failure {
      rethrow;
    } on Object {
      throw _invalid();
    }
  }

  @override
  Future<Result<int>> pageCount(Uint8List bytes) {
    return _serial(
      () => Result.captureAsync(() async {
        try {
          return (await _open(bytes)).pages.length;
        } finally {
          if (identical(_source, bytes)) await _close();
        }
      }),
    );
  }

  @override
  Future<Result<PdfPageImage>> renderPage(
    Uint8List bytes, {
    required int pageIndex,
    required int longEdge,
  }) {
    return _serial(
      () => Result.captureAsync(() async {
        final pdf.PdfDocument document = await _open(bytes);
        if (pageIndex < 0 ||
            pageIndex >= document.pages.length ||
            longEdge < 1) {
          throw ValidationFailure(
            localizedMessage: Copy.messages.pdfPageMissing,
            localizedRecovery: Copy.messages.tryAnotherFile,
          );
        }
        final pdf.PdfPage page = document.pages[pageIndex];
        final int edge = min(longEdge, AppConstants.images.longEdge);
        final double scale = edge / max(page.width, page.height);
        final int width = max(1, (page.width * scale).round());
        final int height = max(1, (page.height * scale).round());
        final pdf.PdfImage? raster = await page.render(
          width: width,
          height: height,
          fullWidth: width.toDouble(),
          fullHeight: height.toDouble(),
          backgroundColor: AppColors.light.surface,
        );
        if (raster == null) throw _invalid();
        try {
          final Result<Uint8List> encoded = await runIsolate(_encodePdfPage, (
            pixels: raster.pixels,
            width: raster.width,
            height: raster.height,
            bgra: raster.format == ui.PixelFormat.bgra8888,
          ));
          final Uint8List png = encoded.fold(
            (Failure failure) => throw failure,
            (Uint8List value) => value,
          );
          return PdfPageImage(
            pageIndex: pageIndex,
            bytes: png,
            width: raster.width,
            height: raster.height,
          );
        } finally {
          raster.dispose();
        }
      }),
    );
  }

  @override
  Future<void> release(Uint8List bytes) => _serial(() async {
    if (identical(_source, bytes)) await _close();
  });

  @override
  Future<void> dispose() => _serial(_close);

  Future<void> _close() async {
    final pdf.PdfDocument? document = _document;
    _document = null;
    _source = null;
    await document?.dispose();
  }

  static ValidationFailure _invalid() => ValidationFailure(
    localizedMessage: Copy.messages.pdfInvalid,
    localizedRecovery: Copy.messages.tryAnotherFile,
  );
}

Uint8List _encodePdfPage(
  ({Uint8List pixels, int width, int height, bool bgra}) data,
) {
  final image.Image decoded = image.Image.fromBytes(
    width: data.width,
    height: data.height,
    bytes: data.pixels.buffer,
    bytesOffset: data.pixels.offsetInBytes,
    numChannels: 4,
    order: data.bgra ? image.ChannelOrder.bgra : image.ChannelOrder.rgba,
  );
  return image.encodePng(decoded);
}
