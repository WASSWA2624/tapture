# 02 — Coding standards

*Enforced by dev-plan tasks 003 (strict lints), 011 (naming), 014 (errors), 015 (logging).*

## FE-CODE-01 — The analyzer is law
`strict-casts`, `strict-inference` and `strict-raw-types` are on, and every warning is an error. A change that needs a
suppression needs a comment saying why, on the same line.

## FE-CODE-02 — Naming
Types `PascalCase`, members and locals `lowerCamelCase`, constants `lowerCamelCase`, files `snake_case`. Providers end
in `Provider`. Booleans read as predicates: `isDirty`, `hasEvidence`, `canApprove`.

## FE-CODE-03 — Banned words in type names
`Manager`, `Helper`, `Util`, `Data`, `Info`, `Item`. They describe nothing. Use the canonical vocabulary in
`lib/core/naming/domain_names.dart`.

## FE-CODE-04 — Models are immutable
Fields are `final`. Construct with `const` where possible. Change through `copyWith`. No public mutable field, ever.

## FE-CODE-05 — No dynamic, no implicit casts
`dynamic` appears only where a decoder demands it, and is narrowed on the next line. Prefer sealed classes and
exhaustive `switch` over type checks.

## FE-CODE-06 — Errors are values at boundaries
Public repository and service methods return `Result<T>`. A raw exception never crosses a layer. `Failure` is sealed
and every variant carries a user-facing message and a recovery action.

## FE-CODE-07 — Async discipline
No floating futures — await it or explicitly `unawaited()` it with a reason. No async work in `build`. Every
long-running call accepts a cancellation path.

## FE-CODE-08 — Logging
`print` and `debugPrint` do not exist in `lib/`. Use the logger with a level and a tag. Never log a key, token,
caption, transcript, field value or file content.

## FE-CODE-09 — No magic values
Numbers, durations and keys come from `AppConstants` or the design tokens. A literal in feature code is a defect,
not a shortcut.

## FE-CODE-10 — Comments earn their place
Comments explain **why**. The code already says what. No commented-out code. A `TODO` must carry a dev-plan task
number, and the guardrail suite rejects one that does not.

## FE-CODE-11 — Imports
`dart format` decides layout; imports stay sorted. Relative imports inside a feature, `package:` imports across
features and into `core/`.

## FE-CODE-12 — Public API in `core/` is documented
One line saying what it is for. If one line is hard to write, the abstraction is wrong.

## FE-CODE-13 — Generated code is committed
Drift and serialisation output is committed so a clean checkout builds without a generator run, and is regenerated in
the same commit as the source change that caused it.
