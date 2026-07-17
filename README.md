# Puzzle Book

A Flutter puzzle game, structured as a Dart workspace of pure-Dart packages
plus (from M2 onward) a Flutter app shell that binds UI to the modules
defined here.

## Layout

```
app/
├─ pubspec.yaml            workspace root (Dart/Flutter workspace)
├─ packages/
│  ├─ core/                puzzle_core: UI-agnostic contracts shared by all
│  │                       puzzle modules (module registry, save/settings/
│  │                       audio services, logging).
│  └─ module_rebus/        module_rebus: the "rebus" arithmetic-square
│                          puzzle module — model, evaluator, verifier,
│                          solver, and the puzzle data set. Flutter UI for
│                          this module is added in M2.
└─ tools/
   └─ solver/              rebus_verify: a thin CLI over module_rebus that
                            validates puzzle data (canonical solution
                            correctness + solution-count uniqueness).
```

## M1 milestone

M1 covers only the pure-Dart packages (`packages/core`, `packages/module_rebus`,
`tools/solver`). No Flutter app exists yet — that is added in a later
milestone once the core puzzle model and data are proven correct.

## Running the verifier

From `tools/solver`:

```
dart run rebus_verify
```

This validates every puzzle in `packages/module_rebus/assets/puzzles/module01.json`:
canonical solution correctness and (for non-tutorial puzzles) that the puzzle
as presented to the player has exactly one solution.

## Running tests

Each package has its own test suite. From within a package directory
(`packages/core`, `packages/module_rebus`, or `tools/solver`):

```
dart test
```
