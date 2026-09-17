# 03 — State and data

*Enforced by dev-plan tasks 014 (state conventions), 010 (layering), 018 (raw-data safety).*

## FE-STATE-01 — Riverpod, and only Riverpod
No other state solution, no service locators, no global singletons. `setState` appears only inside `core/widgets/`
and animation code.

## FE-STATE-02 — Pick the right primitive
`AsyncNotifier` for anything that loads. `Notifier` for ephemeral screen state. `Provider` for pure derivations.
Nothing else without a written reason.

## FE-STATE-03 — Providers live with their feature
Declared in the feature that owns the state, exported through the feature barrel. `core/` never declares a provider
that depends on a feature.

## FE-STATE-04 — Widgets are thin
A widget reads state and calls intent methods on a controller. Business rules, persistence and orchestration live in
the controller or the domain, never in `build`.

## FE-STATE-05 — Repositories are interfaces
Declared in `domain/`, implemented in `data/`. Presentation never sees a DAO, a Drift row, a file handle or a HTTP
client.

## FE-STATE-06 — One source of truth
Derive, never duplicate. If two providers can disagree about the same fact, one of them is wrong by construction.

## FE-STATE-07 — Local-first writes
Persist before the interface confirms. No optimistic update that a failure could silently discard. A crash may cost
at most the last keystroke.

## FE-STATE-08 — Streams for collections
Lists come from `watch` queries so the screen updates itself. One-shot reads use futures. No manual refresh calls
after a write.

## FE-STATE-09 — Dispose by default
`autoDispose` unless keeping the state alive is deliberate and commented. Every subscription, controller and isolate
is released.

## FE-STATE-10 — Every repository has a fake
Tests never touch the platform, the network or a real database except in DAO and integration tests.

## FE-STATE-11 — Failure is part of the state
Async state models loading, data, empty and failure. Screens render all four through `AsyncValueView`.
