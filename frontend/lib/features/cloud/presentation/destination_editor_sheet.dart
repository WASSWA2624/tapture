import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/folder_picker.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import 'destination_editor_controller.dart';
import 'destination_labels.dart';
import 'destination_list_controller.dart';

/// Opens the destination form: blank to add one, or [existing] to rename it
/// or replace its sign-in. Completes with the saved destination, or null.
Future<Destination?> showDestinationEditor(
  BuildContext context, {
  Destination? existing,
}) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppSheet<Destination>(
    context,
    title: existing == null
        ? localCopy.destinationAdd
        : localCopy.destinationEdit,
    contentSized: true,
    builder: (BuildContext _) => DestinationEditorSheet(existing: existing),
  );
}

/// The destination form: a type, a name, and the fields that type needs.
///
/// Its one submit checks the configuration with a probe upload and saves it
/// only when that succeeds (task 021 step 2). Sign-in fields are obscured
/// and never filled back in from storage; left empty on an edit, they keep
/// the saved sign-in.
final class DestinationEditorSheet extends ConsumerStatefulWidget {
  /// Creates the form. [existing] is the destination being changed.
  const DestinationEditorSheet({this.existing, super.key});

  /// The saved destination, or null to add one.
  final Destination? existing;

  @override
  ConsumerState<DestinationEditorSheet> createState() =>
      _DestinationEditorSheetState();
}

class _DestinationEditorSheetState extends ConsumerState<DestinationEditorSheet>
    with StateRefresh {
  final TextEditingController _label = TextEditingController();
  final TextEditingController _folder = TextEditingController();
  final TextEditingController _accessKey = TextEditingController();
  final TextEditingController _secretKey = TextEditingController();
  final TextEditingController _region = TextEditingController();
  final TextEditingController _bucket = TextEditingController();
  final TextEditingController _endpoint = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _token = TextEditingController();

  DestinationKind? _kind;
  bool _useToken = false;
  bool _signInAgain = false;
  bool _tried = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Destination? existing = widget.existing;
    if (existing != null) {
      _kind = existing.kind;
      _label.text = existing.label;
      _folder.text = existing.folder;
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _label,
      _folder,
      _accessKey,
      _secretKey,
      _region,
      _bucket,
      _endpoint,
      _address,
      _username,
      _password,
      _token,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? english = ref.watch(destinationEditorControllerProvider);
    final LocalizedMessage? message = ref
        .read(destinationEditorControllerProvider.notifier)
        .errorMessage;
    final String? refused = message == null
        ? english
        : Copy.of(context).resolve(message);
    return AsyncValueView<List<DestinationKind>>(
      value: ref.watch(destinationKindsProvider),
      onRetry: () => ref.invalidate(destinationKindsProvider),
      loadingCount: 4,
      isEmpty: (List<DestinationKind> kinds) => kinds.isEmpty && !_editing,
      empty: () => AppEmptyState(
        icon: AppIcons.upload,
        headline: Copy.of(context).destinationUnavailableHeadline,
        message: Copy.of(context).destinationUnavailableMessage,
        actionLabel: Copy.of(context).close,
        onAction: () => Navigator.of(context).maybePop(),
      ),
      data: (List<DestinationKind> kinds) {
        final LocalizedCopy localCopy = Copy.of(context);

        final DestinationKind kind =
            _kind ?? widget.existing?.kind ?? kinds.first;
        return AppForm(
          compact: true,
          guardUnsaved: true,
          errors: <String>[?refused],
          fields: <Widget>[
            if (!_editing && kinds.length > 1)
              AppRadioGroup<DestinationKind>(
                key: const ValueKey<String>('destination-kind'),
                label: localCopy.destinationKind,
                options: <Choice<DestinationKind>>[
                  for (final DestinationKind option in kinds)
                    Choice<DestinationKind>(
                      option,
                      destinationKindLabel(option, copy: localCopy),
                    ),
                ],
                value: kind,
                onChanged: (DestinationKind picked) => refresh(() {
                  _kind = picked;
                  _tried = false;
                }),
              ),
            _text(
              _label,
              localCopy.destinationLabel,
              key: 'destination-label',
              kind: kind,
            ),
            ..._kindFields(kind),
          ],
          submitLabel: localCopy.destinationCheckAndSave,
          onSubmit: () => _submit(kind),
        );
      },
    );
  }

  List<Widget> _kindFields(DestinationKind kind) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Widget keepSignIn = AppBanner(
      message: localCopy.destinationKeepSignIn,
      icon: AppIcons.info,
      tone: SnackTone.info,
    );
    return switch (kind) {
      DestinationKind.localFolder => <Widget>[
        _text(
          _folder,
          localCopy.destinationFolder,
          key: 'destination-folder',
          kind: kind,
          hint: localCopy.destinationLocalFolderHint,
        ),
        if (ref.watch(destinationFolderPickerProvider).canPick)
          AppButton(
            key: const ValueKey<String>('destination-choose-folder'),
            label: localCopy.destinationChooseFolder,
            icon: AppIcons.folder,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => unawaited(_chooseFolder()),
          ),
      ],
      DestinationKind.s3 => <Widget>[
        if (_editing) keepSignIn,
        _text(
          _accessKey,
          localCopy.destinationAccessKey,
          key: 's3-access',
          kind: kind,
        ),
        _text(
          _secretKey,
          localCopy.destinationSecretKey,
          key: 's3-secret',
          kind: kind,
          obscure: true,
        ),
        _text(
          _region,
          localCopy.destinationRegion,
          key: 's3-region',
          kind: kind,
        ),
        _text(
          _bucket,
          localCopy.destinationBucket,
          key: 's3-bucket',
          kind: kind,
        ),
        _text(
          _folder,
          localCopy.destinationBucketFolder,
          key: 'destination-folder',
          kind: kind,
          hint: localCopy.destinationOptional,
        ),
        _text(
          _endpoint,
          localCopy.destinationEndpoint,
          key: 's3-endpoint',
          kind: kind,
          hint: localCopy.destinationEndpointHint,
          url: true,
        ),
      ],
      DestinationKind.webdav => <Widget>[
        if (_editing) keepSignIn,
        _text(
          _address,
          localCopy.destinationAddress,
          key: 'webdav-address',
          kind: kind,
          hint: localCopy.destinationAddressHint,
          url: true,
        ),
        _text(
          _folder,
          localCopy.destinationFolder,
          key: 'destination-folder',
          kind: kind,
          hint: localCopy.destinationOptional,
        ),
        AppChoiceField<bool>(
          key: const ValueKey<String>('webdav-method'),
          label: localCopy.destinationSignInMethod,
          options: <Choice<bool>>[
            Choice<bool>(false, localCopy.destinationSignInPassword),
            Choice<bool>(true, localCopy.destinationSignInToken),
          ],
          value: _useToken,
          onChanged: (bool? token) => refresh(() => _useToken = token ?? false),
        ),
        if (_useToken)
          _text(
            _token,
            localCopy.destinationToken,
            key: 'webdav-token',
            kind: kind,
            obscure: true,
          )
        else ...<Widget>[
          _text(
            _username,
            localCopy.destinationUsername,
            key: 'webdav-username',
            kind: kind,
          ),
          _text(
            _password,
            localCopy.destinationPassword,
            key: 'webdav-password',
            kind: kind,
            obscure: true,
          ),
        ],
      ],
      DestinationKind.googleDrive ||
      DestinationKind.oneDrive ||
      DestinationKind.dropbox => <Widget>[
        _text(
          _folder,
          localCopy.destinationFolder,
          key: 'destination-folder',
          kind: kind,
          hint: localCopy.destinationOptional,
        ),
        AppBanner(
          message: localCopy.destinationSignInNote(
            destinationKindLabel(kind, copy: localCopy),
          ),
          icon: AppIcons.info,
          tone: SnackTone.info,
        ),
        if (_editing)
          AppSwitchTile.checkbox(
            key: const ValueKey<String>('destination-sign-in-again'),
            title: localCopy.destinationSignInAgain,
            value: _signInAgain,
            onChanged: (bool value) => refresh(() => _signInAgain = value),
          ),
      ],
    };
  }

  AppTextField _text(
    TextEditingController controller,
    String label, {
    required String key,
    required DestinationKind kind,
    String? hint,
    bool obscure = false,
    bool url = false,
  }) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool required = _required(kind).contains(controller);
    return AppTextField(
      key: ValueKey<String>(key),
      label: label,
      controller: controller,
      hint: hint,
      obscureText: obscure,
      dictation: false,
      keyboardType: url ? TextInputType.url : null,
      textInputAction: TextInputAction.next,
      requiredness: required
          ? FieldRequiredness.required
          : FieldRequiredness.unmarked,
      errorText: _tried && required && controller.text.trim().isEmpty
          ? localCopy.fieldRequired
          : null,
    );
  }

  /// The sign-in fields [kind] has. On an edit, filling any of them
  /// replaces the saved sign-in, so the rest become required.
  List<TextEditingController> _connectionFields(DestinationKind kind) {
    return switch (kind) {
      DestinationKind.s3 => <TextEditingController>[
        _accessKey,
        _secretKey,
        _region,
        _bucket,
        _endpoint,
      ],
      DestinationKind.webdav => <TextEditingController>[
        _address,
        _username,
        _password,
        _token,
      ],
      DestinationKind.localFolder ||
      DestinationKind.googleDrive ||
      DestinationKind.oneDrive ||
      DestinationKind.dropbox => const <TextEditingController>[],
    };
  }

  bool _replacesSignIn(DestinationKind kind) {
    return !_editing ||
        _connectionFields(
          kind,
        ).any((TextEditingController field) => field.text.trim().isNotEmpty);
  }

  Set<TextEditingController> _required(DestinationKind kind) {
    final List<TextEditingController> connection = switch (kind) {
      DestinationKind.s3 => <TextEditingController>[
        _accessKey,
        _secretKey,
        _region,
        _bucket,
      ],
      DestinationKind.webdav => <TextEditingController>[
        _address,
        if (_useToken) _token else _username,
      ],
      DestinationKind.localFolder ||
      DestinationKind.googleDrive ||
      DestinationKind.oneDrive ||
      DestinationKind.dropbox => const <TextEditingController>[],
    };
    return <TextEditingController>{
      _label,
      if (_replacesSignIn(kind)) ...connection,
    };
  }

  /// The sign-in payload for secure storage, or null to keep the saved one.
  String? _connection(DestinationKind kind) {
    if (!_replacesSignIn(kind)) {
      return null;
    }
    String value(TextEditingController field) => field.text.trim();
    return switch (kind) {
      DestinationKind.s3 => jsonEncode(<String, String>{
        'accessKey': value(_accessKey),
        'secret': value(_secretKey),
        'region': value(_region),
        'bucket': value(_bucket),
        if (value(_endpoint).isNotEmpty) 'endpoint': value(_endpoint),
      }),
      DestinationKind.webdav => jsonEncode(<String, String>{
        'baseUrl': value(_address),
        if (_useToken) 'bearer': value(_token),
        if (!_useToken) 'username': value(_username),
        if (!_useToken) 'password': _password.text,
      }),
      DestinationKind.localFolder ||
      DestinationKind.googleDrive ||
      DestinationKind.oneDrive ||
      DestinationKind.dropbox => null,
    };
  }

  Future<bool> _submit(DestinationKind kind) async {
    if (_required(
      kind,
    ).any((TextEditingController field) => field.text.trim().isEmpty)) {
      refresh(() => _tried = true);
      return false;
    }
    final Destination? saved = await ref
        .read(destinationEditorControllerProvider.notifier)
        .save((
          existing: widget.existing,
          kind: kind,
          label: _label.text,
          folder: _folder.text,
          connection: _connection(kind),
          signIn: _signInAgain,
        ));
    if (saved == null || !mounted) {
      return false;
    }
    // The form forgets its edits once this returns, so close on the next
    // frame, when there is nothing left to guard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    });
    return true;
  }

  Future<void> _chooseFolder() async {
    final Result<String?> picked = await ref
        .read(destinationFolderPickerProvider)
        .pick();
    if (!mounted) {
      return;
    }
    switch (picked) {
      case Success<String?>(:final String? value)
          when value != null && value.isNotEmpty:
        _folder.text = value;
      case FailureResult<String?>(:final Failure failure)
          when failure is! CancelledFailure:
        showAppSnack(
          context,
          Copy.of(context).failureMessage(failure),
          tone: SnackTone.error,
        );
      case Success<String?>() || FailureResult<String?>():
        break;
    }
  }
}
