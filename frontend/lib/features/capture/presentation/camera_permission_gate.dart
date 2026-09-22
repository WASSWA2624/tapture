import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/widgets/app_button.dart';

/// Asks for the camera at first need with a visible reason.
final class CameraPermissionGate extends StatefulWidget {
  /// Creates a gate.
  const CameraPermissionGate({
    required this.permissions,
    required this.child,
    this.onOpenSettings,
    super.key,
  });

  /// Permission port.
  final PermissionsService permissions;

  /// Preview when granted.
  final Widget child;

  /// Permanent denial route to settings.
  final VoidCallback? onOpenSettings;

  @override
  State<CameraPermissionGate> createState() => _CameraPermissionGateState();
}

class _CameraPermissionGateState extends State<CameraPermissionGate> {
  PermissionState? _state;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final PermissionState status = await widget.permissions.status(
      AppPermission.camera,
    );
    if (mounted) {
      setState(() => _state = status);
    }
  }

  Future<void> _ask() async {
    setState(() => _asking = true);
    await widget.permissions.request(AppPermission.camera);
    await _refresh();
    if (mounted) {
      setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PermissionState? state = _state;
    if (state == PermissionState.granted) {
      return widget.child;
    }
    return Semantics(
      label: Copy.captureCameraReason,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(Copy.captureCameraReason, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (state == PermissionState.permanentlyDenied)
              AppButton(
                label: Copy.captureOpenCameraSettings,
                onPressed: widget.onOpenSettings ?? _ask,
              )
            else
              AppButton(
                label: Copy.captureTitle,
                onPressed: _asking ? null : _ask,
              ),
          ],
        ),
      ),
    );
  }
}
