# Tasks: tx-rdf-core package split

**Input**: Design documents from `specs/090-tx-rdf-core/`
**Prerequisites**: plan.md, spec.md

**Tests**: Tests and goldens are required because this is a package-boundary
change with public build behavior.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel after dependencies are satisfied
- **[Story]**: Which user story the task supports
- Include exact file paths in descriptions

## Phase 1: Setup and Boundary Proof

**Purpose**: Establish the split contract before source changes.

- [X] T001 Record the module classification and any corrections in `specs/090-tx-rdf-core/plan.md`
- [X] T002 [P] Add a package-boundary verification test or script for `tx-rdf-core` dependency exclusions in `test/` or `scripts/`
- [X] T003 [P] Identify exact existing golden tests that prove byte-identical emit output in `specs/090-tx-rdf-core/plan.md`

---

## Phase 2: User Story 1 - Lean RDF Core Consumer (Priority: P1)

**Goal**: `tx-rdf-core` builds independently with only pure transaction RDF
modules and lean dependencies.

**Independent Test**: Build only `tx-rdf-core` and prove its dependency tree
does not contain fat packages.

### Tests for User Story 1

- [X] T004 [US1] Add or update the failing package-boundary test/proof for forbidden `tx-rdf-core` dependencies in `test/` or `scripts/`

### Implementation for User Story 1

- [X] T005 [US1] Add the `tx-rdf-core` package metadata and local package wiring in `cardano-ledger-rdf.cabal` and/or `cabal.project`
- [X] T006 [US1] Assign pure modules (`Cardano.Tx.Decode`, `Cardano.Tx.Blueprint`, `Cardano.Tx.Graph.Emit/**`, pure Turtle rule parsing/types, `Cardano.Tx.View/**`) to `tx-rdf-core`
- [X] T007 [US1] Split any mixed rule-loader surface so core gets only pure types/Turtle parsing and fat code keeps YAML/import IO
- [X] T008 [US1] Prove `nix develop --quiet -c cabal build tx-rdf-core:lib:tx-rdf-core -O0` succeeds
- [X] T009 [US1] Prove the `tx-rdf-core` dependency closure excludes `http-client`, `http-client-tls`, `libyaml`, `yaml`, `optparse-applicative`, `directory`, `filepath`, and `process`

---

## Phase 3: User Story 2 - Existing CLI Compatibility (Priority: P2)

**Goal**: Existing fat library and executables continue to build and behave as
before while consuming `tx-rdf-core`.

**Independent Test**: Build all components and run existing unit/golden tests.

### Tests for User Story 2

- [X] T010 [US2] Run the existing emit golden tests and confirm byte-identical Turtle output

### Implementation for User Story 2

- [X] T011 [US2] Update `cardano-ledger-rdf` library dependencies/imports so fat modules consume `tx-rdf-core`
- [X] T012 [US2] Update executable dependencies for `cq-rdf` and `tx-view` so both build through the split packages
- [X] T013 [US2] Update tests/build-tool dependencies so pure tests can see `tx-rdf-core` and CLI tests can see fat executables
- [X] T014 [US2] Prove `nix develop --quiet -c cabal build all -O0` succeeds
- [X] T015 [US2] Prove `nix develop --quiet -c just unit` succeeds

---

## Phase 4: Final Verification

**Purpose**: Prove acceptance and prepare the PR.

- [X] T016 Run `nix build` and record the result
- [X] T017 Run `nix develop --quiet -c just ci` and record the result
- [X] T018 Verify `tx-rdf-core` against the inspector CHaP pin dated 2026-04-15, or write a Q-file with exact incompatibility details
- [X] T019 Update PR metadata for issue #90 with package split, dependency proof, golden proof, and verification evidence

## Dependencies & Execution Order

- Phase 1 blocks all source changes.
- Phase 2 must complete before Phase 3 because the fat package consumes the
  core package.
- Phase 4 starts only after both user stories pass locally.

## Parallel Opportunities

- T002 and T003 can run in parallel after T001.
- After package wiring exists, pure module assignment and mixed loader split can
  be reviewed independently but must commit together to stay bisect-safe.

## Implementation Strategy

Use one visible Codex driver plus one Claude QA navigator for the package split
slice. The slice is expected to be one bisect-safe commit covering cabal/source
test updates because intermediate package states are unlikely to build.
