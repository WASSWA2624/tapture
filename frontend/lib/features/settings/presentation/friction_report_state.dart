import 'package:tapture/core/errors/failure.dart';

/// Optional evidence choice and the result of the current durable submission.
typedef FrictionReportState = ({bool saving, bool screenshot, Failure? error});
