import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_operation_policy.dart';

/// Composition root binds committed privacy preferences and live connectivity.
final Provider<CloudOperationPolicy> cloudOperationPolicyProvider =
    Provider<CloudOperationPolicy>(
      (Ref _) => const CloudOperationPolicy.unrestricted(),
    );
