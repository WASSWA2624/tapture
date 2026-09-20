import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_template_repository.dart';
import '../template_repository_contract.dart';

void main() {
  late FakeTemplateRepository repo;

  setUp(() {
    repo = FakeTemplateRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  runTemplateRepositoryContract(() => repo);
}
