/// The cloud feature: uploading to a destination the person chooses.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/result.dart';

export 'data/data.dart';
export 'domain/domain.dart';
export 'presentation/presentation.dart';

/// Composition root supplies the sharing policy before any transfer attempt.
final Provider<Future<Result<void>> Function(String)> cloudExportGuardProvider =
    Provider<Future<Result<void>> Function(String)>(
      (Ref _) =>
          (String _) async => const Success<void>(null),
    );
