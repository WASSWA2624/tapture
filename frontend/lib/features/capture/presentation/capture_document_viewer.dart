import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/import/pdf_pages.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import '../domain/document_draft.dart';
import 'capture_document_viewer_controller.dart';

/// Shows disposable pages of a durable original document.
final class CaptureDocumentViewer extends ConsumerWidget {
  /// Opens an attachment, persisting [onAddPage] before confirmation.
  const CaptureDocumentViewer({
    required this.document,
    required this.folder,
    required this.onAddPage,
    super.key,
  });

  /// Original metadata.
  final DocumentDraft document;

  /// Stored project folder.
  final String folder;

  /// Stores a normalized page photo before confirming the addition.
  final Future<Result<void>> Function(Uint8List jpeg) onAddPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (!document.canRenderPages) {
      return AppPage(
        title: document.originalFilename,
        body: AppErrorState(
          failure: ValidationFailure(
            message: localCopy.captureDocumentInvalid(
              document.originalFilename,
            ),
            recoveryAction: localCopy.tryAnotherFile,
          ),
        ),
      );
    }
    final int pageCount = document.pageCount!;
    final view = ref.watch(captureDocumentViewerControllerProvider(document));
    final CaptureDocumentViewerController controller = ref.read(
      captureDocumentViewerControllerProvider(document).notifier,
    );
    final AsyncValue<PdfPageImage> page = ref.watch(
      captureDocumentPageProvider((
        path: 'projects/$folder/${document.relativePath}',
        sha: document.sha256,
        index: view.index,
      )),
    );
    return AppPage(
      title: document.originalFilename,
      subtitle: localCopy.pdfPageOf(view.index + 1, pageCount),
      scrollable: false,
      body: page.when(
        loading: () => const AppSkeleton(),
        error: (Object error, StackTrace _) =>
            AppErrorState(failure: Failure.from(error)),
        data: (PdfPageImage image) => Column(
          children: <Widget>[
            Expanded(
              child: InteractiveViewer(
                child: Image.memory(image.bytes, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: Space.x2),
            AppButton(
              label: Copy.of(context).captureAddPhoto,
              onPressed: view.adding
                  ? null
                  : () async {
                      final Result<void> result = await controller.add(
                        image,
                        onAddPage,
                      );
                      if (context.mounted) {
                        if (result case FailureResult<void>(
                          :final Failure failure,
                        )) {
                          showAppSnack(
                            context,
                            failure.message,
                            tone: SnackTone.error,
                            localizedMessage: failure.explanation,
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
      footer: Row(
        children: <Widget>[
          Expanded(
            child: AppButton(
              label: localCopy.pdfPreviousPage,
              onPressed: view.adding || view.index == 0
                  ? null
                  : () => controller.move(view.index - 1),
            ),
          ),
          const SizedBox(width: Space.x2),
          Expanded(
            child: AppButton(
              label: localCopy.pdfNextPage,
              onPressed: view.adding || view.index + 1 >= pageCount
                  ? null
                  : () => controller.move(view.index + 1),
            ),
          ),
        ],
      ),
    );
  }
}
