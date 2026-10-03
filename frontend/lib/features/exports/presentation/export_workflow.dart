import 'package:tapture/core/export/export_request.dart';

import '../domain/deliverable_repository.dart';

/// One export session; completed files remain available for explicit sharing.
final class ExportWorkflow {
  const ExportWorkflow({
    required this.request,
    this.running = false,
    this.advanced = false,
    this.progress = const <String, double>{},
    this.saved,
    this.withoutPhotos = false,
    this.password,
  });

  final bool withoutPhotos;
  final String? password;
  final ExportRequest request;
  final bool running;
  final bool advanced;
  final Map<String, double> progress;
  final DeliverableEntry? saved;

  ExportWorkflow copyWith({
    ExportRequest? request,
    bool? running,
    bool? advanced,
    Map<String, double>? progress,
    DeliverableEntry? saved,
    bool? withoutPhotos,
    String? password,
  }) => ExportWorkflow(
    request: request ?? this.request,
    running: running ?? this.running,
    advanced: advanced ?? this.advanced,
    progress: progress ?? this.progress,
    saved: saved ?? this.saved,
    withoutPhotos: withoutPhotos ?? this.withoutPhotos,
    password: password ?? this.password,
  );
}
