import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_operation.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/model_descriptor.dart';
import 'package:tapture/core/ai/provider_descriptor.dart';
import 'package:tapture/core/ai/provider_key_custody.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/settings/presentation/egress_summary_screen.dart';

void main() {
  final ProviderDescriptor backend = _provider('backend', 'Organisation');
  final ProviderDescriptor extra = _provider('local-ocr', 'On-device reader');

  testWidgets('empty, all off, all on and failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const _App(EgressSummaryScreen()));
    expect(find.byType(AppEmptyState), findsOneWidget);

    await tester.pumpWidget(
      _App(
        EgressSummaryScreen(
          providers: <ProviderDescriptor>[backend],
          destinations: const <Destination>[_destination],
        ),
      ),
    );
    final Finder operation = find.byKey(
      const ValueKey<String>('egress-backend-extractFields'),
    );
    expect(tester.widget<AppSwitchTile>(operation).value, isFalse);

    await tester.pumpWidget(
      _App(
        EgressSummaryScreen(
          providers: <ProviderDescriptor>[backend],
          destinations: const <Destination>[_destination],
          operationEnabled: (_) => true,
          uploadEnabled: (_) => true,
        ),
      ),
    );
    expect(tester.widget<AppSwitchTile>(operation).value, isTrue);

    await tester.pumpWidget(const _App(EgressSummaryScreen(loading: true)));
    expect(find.byType(AppSkeleton), findsOneWidget);

    await tester.pumpWidget(
      const _App(
        EgressSummaryScreen(
          failure: StorageFailure(
            message: 'The privacy summary could not be read.',
            recoveryAction: 'Try again.',
          ),
        ),
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets(
    'a newly registered provider appears without editing the screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _App(
          EgressSummaryScreen(
            providers: <ProviderDescriptor>[backend, extra],
            operationEnabled: (_) => true,
            destinations: const <Destination>[_destination],
            uploadEnabled: (_) => true,
          ),
        ),
      );
      expect(find.text('On-device reader'), findsWidgets);
      expect(find.text('Archive'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('egress-local-ocr-extractFields')),
        findsOneWidget,
      );
    },
  );
}

ProviderDescriptor _provider(String id, String label) {
  return ProviderDescriptor(
    id: id,
    label: label,
    operations: const <AiOperation>{AiOperation.extractFields},
    keyCustody: ProviderKeyCustody.backend,
    deviceKeyAllowed: false,
    available: false,
    service: const AiService.unavailable(),
    models: <ModelDescriptor>[
      ModelDescriptor(
        id: 'default',
        label: 'Default',
        operations: const <AiOperation>{AiOperation.extractFields},
      ),
    ],
  );
}

const Destination _destination = (
  id: 'dest',
  kind: DestinationKind.s3,
  label: 'Archive',
  folder: 'inbox',
  credentialRef: 'ref',
  lastCheck: null,
);

class _App extends StatelessWidget {
  const _App(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: child);
  }
}
