import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/presentation/image_egress_switch.dart';

void main() {
  testWidgets('empty, on and failure', (WidgetTester tester) async {
    await tester.pumpWidget(const _Host(ImageEgressSwitch()));
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(const _Host(ImageEgressSwitch(holdImages: true)));
    expect(find.text(Copy.egressTextOnly), findsOneWidget);
    await tester.pumpWidget(
      const _Host(
        ImageEgressSwitch(
          failure: StorageFailure(
            message: 'The switch could not be read.',
            recoveryAction: 'Try again.',
          ),
        ),
      ),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
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
