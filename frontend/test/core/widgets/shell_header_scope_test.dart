import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';

void main() {
  testWidgets('a page outside the scope keeps its own bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppPage(title: 'Storage', body: Text('Body')),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
    expect(
      ShellHeaderScope.ownsHeaderOf(tester.element(find.byType(AppPage))),
      isFalse,
    );
  });

  testWidgets('the visible page publishes its title and actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShellHeaderScope(
          ownsHeader: true,
          child: Column(
            children: <Widget>[
              _Reader(),
              _Publisher(title: 'Storage'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Storage'), findsOneWidget);
    final BuildContext context = tester.element(find.text('Body'));
    expect(ShellHeaderScope.chromeOf(context)?.title, 'Storage');
    expect(ShellHeaderScope.chromeOf(context)?.actions, hasLength(1));
    expect(
      ShellHeaderScope.chromeOf(context)?.overflow.single.label,
      Copy.save,
    );
  });

  testWidgets('an offstage page does not replace the visible header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShellHeaderScope(
          ownsHeader: true,
          child: Stack(
            children: <Widget>[
              _Publisher(title: 'Storage'),
              Offstage(child: _Publisher(title: 'Projects')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      ShellHeaderScope.chromeOf(tester.element(find.text('Body').first))?.title,
      'Storage',
    );
  });
}

class _Reader extends StatelessWidget {
  const _Reader();

  @override
  Widget build(BuildContext context) {
    return Text(ShellHeaderScope.chromeOf(context)?.title ?? '');
  }
}

class _Publisher extends StatefulWidget {
  const _Publisher({required this.title});

  final String title;

  @override
  State<_Publisher> createState() => _PublisherState();
}

class _PublisherState extends State<_Publisher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ShellHeaderScope.publish(
        context,
        owner: this,
        title: widget.title,
        actions: const <Widget>[Icon(Icons.add)],
        overflow: const <AppOverflowAction>[
          AppOverflowAction(label: Copy.save, onTap: _ignore),
        ],
      );
    });
  }

  @override
  void deactivate() {
    ShellHeaderScope.release(context, this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => const Text('Body');
}

void _ignore() {}
