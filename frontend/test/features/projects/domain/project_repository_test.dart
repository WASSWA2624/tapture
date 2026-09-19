import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_project_repository.dart';
import '../project_repository_contract.dart';

void main() {
  late FakeProjectRepository repo;

  setUp(() {
    repo = FakeProjectRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  runProjectRepositoryContract(() => repo);
}
