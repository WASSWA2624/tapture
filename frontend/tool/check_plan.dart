import 'dart:io';

import 'plan_source.dart';

/// Where the plan sits relative to `frontend/`, which is where the checkers
/// run from.
///
/// The plan is a sibling of the application, never something it imports
/// (`frontend/.rules/01-structure.md`, FE-STR-01), so this tool reaches out of
/// the package to read it rather than pulling it in.
const String _defaultPlanRoot = '../dev-plan';

/// Checks the plan's own structure, printing one line per violation.
///
/// Takes the plan directory to scan, defaulting to the plan beside this
/// package. Exits 0 when the plan holds together and 1 on any structural
/// error: a stray file, a step or task heading that disagrees with its name,
/// a hole or duplicate in the numbering, a title used twice, a missing
/// section, a Definition of done nobody can tick, and a dependency that does
/// not resolve or points forward. Reports all of them, so one run says
/// everything that has to change.
Future<int> main(List<String> args) async {
  final PlanSource plan = readPlan(
    Directory(args.isEmpty ? _defaultPlanRoot : args.first),
  );
  for (final PlanProblem problem in plan.problems) {
    stderr.writeln('${problem.file}:${problem.line}: ${problem.message}');
  }
  stdout.writeln(
    plan.problems.isEmpty
        ? 'plan: ${plan.steps.length} steps, ${plan.tasks.length} tasks, '
              'numbering and links intact'
        : 'plan: ${plan.problems.length} violation(s)',
  );
  exitCode = plan.problems.isEmpty ? 0 : 1;
  return exitCode;
}
