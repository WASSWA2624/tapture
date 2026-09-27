import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/records/presentation/record_selection.dart';

void main() {
  late ProviderContainer container;
  late ProviderSubscription<Set<String>> watching;

  RecordSelection selectionOf(String projectId) {
    return container.read(recordSelectionProvider(projectId).notifier);
  }

  Set<String> ticked(String projectId) {
    return container.read(recordSelectionProvider(projectId));
  }

  setUp(() {
    container = ProviderContainer();
    // A list on screen keeps the selection alive, as a watching widget does.
    watching = container.listen<Set<String>>(
      recordSelectionProvider('project-1'),
      (Set<String>? _, Set<String> _) {},
    );
  });

  tearDown(() {
    watching.close();
    container.dispose();
  });

  test('a new list has nothing ticked and is not in selection mode', () {
    expect(ticked('project-1'), isEmpty);
    expect(selectionOf('project-1').isActive, isFalse);
    expect(selectionOf('project-1').count, 0);
  });

  test('toggle ticks a record, then unticks it', () {
    final RecordSelection selection = selectionOf('project-1');

    selection.toggle('record-1');
    expect(ticked('project-1'), <String>{'record-1'});
    expect(selection.isActive, isTrue);
    expect(selection.isSelected('record-1'), isTrue);

    selection.toggle('record-1');
    expect(ticked('project-1'), isEmpty);
    expect(selection.isActive, isFalse);
    expect(selection.isSelected('record-1'), isFalse);
  });

  test('select ticks a record once however often it is called', () {
    final RecordSelection selection = selectionOf('project-1');

    selection.select('record-1');
    selection.select('record-1');

    expect(ticked('project-1'), <String>{'record-1'});
    expect(selection.count, 1);
  });

  test('select all adds every id and keeps those already ticked', () {
    final RecordSelection selection = selectionOf('project-1')
      ..select('record-9');

    selection.selectAll(<String>['record-1', 'record-2', 'record-9']);

    expect(ticked('project-1'), <String>{'record-9', 'record-1', 'record-2'});
    expect(selection.count, 3);
  });

  test('deselect all unticks only the ids it is given', () {
    final RecordSelection selection = selectionOf('project-1')
      ..selectAll(<String>['record-1', 'record-2', 'record-3']);

    selection.deselectAll(<String>['record-1', 'record-3', 'record-7']);

    expect(ticked('project-1'), <String>{'record-2'});
  });

  test('clear unticks everything and leaves selection mode', () {
    final RecordSelection selection = selectionOf('project-1')
      ..selectAll(<String>['record-1', 'record-2']);

    selection.clear();

    expect(ticked('project-1'), isEmpty);
    expect(selection.isActive, isFalse);
  });

  test('a call that changes nothing does not notify the list', () {
    final RecordSelection selection = selectionOf('project-1')
      ..select('record-1');
    int notified = 0;
    final ProviderSubscription<Set<String>> counting = container
        .listen<Set<String>>(
          recordSelectionProvider('project-1'),
          (Set<String>? _, Set<String> _) => notified++,
        );
    addTearDown(counting.close);

    selection.select('record-1');
    selection.selectAll(<String>['record-1']);
    selection.deselectAll(<String>['record-5']);
    selectionOf('project-1').clear();
    selection.clear();

    expect(notified, 1, reason: 'only the first clear changed anything');
  });

  test('the ticked set cannot be changed behind the notifier', () {
    selectionOf('project-1').select('record-1');

    expect(() => ticked('project-1').add('record-2'), throwsUnsupportedError);
  });

  test('two projects never share a selection', () {
    final ProviderSubscription<Set<String>> other = container
        .listen<Set<String>>(
          recordSelectionProvider('project-2'),
          (Set<String>? _, Set<String> _) {},
        );
    addTearDown(other.close);

    selectionOf('project-1').select('record-1');
    selectionOf('project-2').select('record-8');

    expect(ticked('project-1'), <String>{'record-1'});
    expect(ticked('project-2'), <String>{'record-8'});
    expect(selectionOf('project-2').projectId, 'project-2');
  });

  test('leaving the list drops its selection', () async {
    selectionOf('project-1').select('record-1');

    watching.close();
    await container.pump();

    expect(container.exists(recordSelectionProvider('project-1')), isFalse);
    watching = container.listen<Set<String>>(
      recordSelectionProvider('project-1'),
      (Set<String>? _, Set<String> _) {},
    );
    expect(ticked('project-1'), isEmpty);
  });
}
