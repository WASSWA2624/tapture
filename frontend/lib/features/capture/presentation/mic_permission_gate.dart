import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/widgets/app_button.dart';

/// Asks for the microphone on first mic tap only.
final class MicPermissionGate extends StatefulWidget {
  /// Creates a gate.
  const MicPermissionGate({
    required this.permissions,
    required this.child,
    this.deniedChild,
    super.key,
  });

  /// Permission port.
  final PermissionsService permissions;

  /// Content when granted (or before ask — typing stays available).
  final Widget child;

  /// Optional denied affordance; typing remains in [child] by default.
  final Widget? deniedChild;

  @override
  State<MicPermissionGate> createState() => _MicPermissionGateState();
}

class _MicPermissionGateState extends State<MicPermissionGate> {
  PermissionState _state = PermissionState.denied;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final PermissionState status = await widget.permissions.status(
      AppPermission.microphone,
    );
    if (mounted) {
      setState(() => _state = status);
    }
  }

  /// Call from the mic button before listening.
  Future<bool> request() async {
    await widget.permissions.request(AppPermission.microphone);
    await _refresh();
    return _state == PermissionState.granted;
  }

  @override
  Widget build(BuildContext context) {
    if (_state == PermissionState.granted) {
      return widget.child;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        widget.child,
        if (_state == PermissionState.denied ||
            _state == PermissionState.permanentlyDenied) ...<Widget>[
          const Text(Copy.captureMicReason),
          AppButton(label: Copy.captureListening, onPressed: request),
          if (widget.deniedChild != null) widget.deniedChild!,
        ],
      ],
    );
  }
}
