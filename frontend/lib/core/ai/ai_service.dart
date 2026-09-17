import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

part 'extract_fields_request.dart';
part 'extract_fields_result.dart';
part 'read_text_request.dart';
part 'read_text_result.dart';
part 'refine_text_request.dart';
part 'refine_text_result.dart';
part 'transcribe_request.dart';
part 'transcribe_result.dart';

/// The single abstraction every AI provider implements.
///
/// Features call this type only. A provider SDK, an HTTP client and a key
/// never appear on it: custody belongs to the organisation's backend by
/// default (FE-SEC-02, FE-SEC-03). OCR text, transcripts and template labels
/// travel on the request types as data, never inside an instruction string
/// (FE-SEC-05).
abstract interface class AiService {
  /// The stand-in used when AI is disabled or no provider is selected.
  ///
  /// Every method returns [ProviderFailure] with a recovery action.
  const factory AiService.unavailable() = _UnavailableAiService;

  /// Reads text from images.
  Future<Result<ReadTextResult>> readText(ReadTextRequest request);

  /// Extracts field values from a record's evidence against a template.
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  );

  /// Rewrites [request] without adding facts the raw text did not contain.
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request);

  /// Turns a spoken clip into text.
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request);
}

final class _UnavailableAiService implements AiService {
  const _UnavailableAiService();

  static const ProviderFailure _unavailable = ProviderFailure(
    message: 'AI is not available.',
    recoveryAction: 'Continue capturing. Analysis can wait.',
  );

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) {
    return Future<Result<ReadTextResult>>.value(
      const FailureResult<ReadTextResult>(_unavailable),
    );
  }

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) {
    return Future<Result<ExtractFieldsResult>>.value(
      const FailureResult<ExtractFieldsResult>(_unavailable),
    );
  }

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) {
    return Future<Result<RefineTextResult>>.value(
      const FailureResult<RefineTextResult>(_unavailable),
    );
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) {
    return Future<Result<TranscribeResult>>.value(
      const FailureResult<TranscribeResult>(_unavailable),
    );
  }
}
