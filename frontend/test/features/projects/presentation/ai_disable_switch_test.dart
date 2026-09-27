import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/presentation/ai_disable_switch.dart';

void main() {
  testWidgets('empty, on and failure', (WidgetTester tester) async {
    await tester.pumpWidget(const _Host(AiDisableSwitch()));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(const _Host(AiDisableSwitch(manual: true)));
    expect(find.byKey(const ValueKey<String>('ai-disable')), findsOneWidget);
    await tester.pumpWidget(
      const _Host(
        AiDisableSwitch(
          failure: StorageFailure(
            message: 'The switch could not be read.',
            recoveryAction: 'Try again.',
          ),
        ),
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  test('a project with AI off makes no outbound call', () async {
    var calls = 0;
    await AiDisableSwitch.guard(
      aiEnabled: false,
      send: () async {
        calls++;
      },
    );
    expect(calls, 0);
    await AiDisableSwitch.guard(
      aiEnabled: true,
      send: () async {
        calls++;
      },
    );
    expect(calls, 1);
  });
}

class _Host extends StatelessWidget {
  const _Host(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.ltr, child: child);
  }
}
