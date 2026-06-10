# Feature Specification: depend on cardano-tx-tools:tx-build for fixtures, delete the local builder copy

**Feature Branch**: `refactor/86-tx-build-dependency`
**Issue**: lambdasistemi/cardano-ledger-rdf#86
**Status**: In progress
**Blocked by**: lambdasistemi/cardano-tx-tools#127 (drift reconciliation must merge first)

## Problem

The repository duplicates the transaction-builder modules from
cardano-tx-tools (now its pure public sub-library `tx-build`,
lambdasistemi/cardano-tx-tools#123). The copy is used only by the fixture
generators under `test/fixtures/tx-graph/` — nothing in the RDF core
imports it — yet it is exposed as public API and has drifted from the
canonical copy (~73 diff lines in `Build.hs`). Both packages expose the
same `Cardano.Tx.*` module names, an ambiguous-module hazard for any
downstream depending on both.

## User Stories

### US1 — Single source of truth for the builder (P1)

As the maintainer of both repositories, I want the transaction builder to
live only in `cardano-tx-tools:tx-build`, so that fixes land once and the
fixture generators here can never drift from the canonical builder again.

**Acceptance**: the test-suite builds against
`cardano-tx-tools:tx-build`; no builder module source remains under
`src/Cardano/Tx/`; every golden Turtle/JSON-LD byte is identical to main.

### US2 — Library API gains no builder surface and no new dependency (P1)

As a downstream consumer of `cardano-ledger-rdf`, I want the library to
stop exposing builder modules and to gain no new package dependency, so
that depending on both packages is unambiguous and the emitter keeps
walking ledger-native types directly.

**Acceptance**: `cardano-tx-tools` appears only in the test-suite
`build-depends`; the library exposed-modules contain no
`Cardano.Tx.{Build,Balance,Evaluate,Witnesses,Deposits,Scripts,Credentials,Inputs,Ledger}`.

### US3 — Acyclic cross-repo dependency policy is recorded (P2)

As a contributor to either repository, I want the integration policy
written down in this repo's README, so the dependency graph stays acyclic
by construction: cardano-tx-tools consumes cq-rdf at the CLI boundary
(pipes over `cq-rdf body` output), never by linking this library.

**Acceptance**: README states the policy; the cardano-tx-tools README
side is owned by that repository (out of scope here).

## Functional Requirements

- **FR-001**: `cabal.project` pins cardano-tx-tools via
  `source-repository-package` with a nix32 `--sha256:` comment, at the
  commit containing the #127 drift reconciliation.
- **FR-002**: `cardano-tx-tools:tx-build` is added to the test-suite
  `build-depends` only; library and executables gain no new dependency.
- **FR-003**: The local builder copy is deleted:
  `src/Cardano/Tx/{Build,Balance,Evaluate,Witnesses,Deposits,Scripts,Credentials,Inputs}.hs`,
  `test/Cardano/Tx/BuildSpec.hs`, `test/Cardano/Tx/Build/MinUtxoSpec.hs`,
  and their cabal entries. (Pre-approved deletion list; do not exceed it.)
- **FR-004**: `Cardano.Tx.Ledger` is inlined: `ConwayTx` moves to
  `Cardano.Tx.Decode` (kept RDF input boundary), all in-repo importers
  retarget, and `src/Cardano/Tx/Ledger.hs` is deleted so the test-suite
  resolves builder module names only to tx-build's copies.
- **FR-005**: `Cardano.Tx.Decode` and `Cardano.Tx.Blueprint` remain
  exposed (RDF input boundary; not part of tx-build).
- **FR-006**: README records the CLI-boundary integration policy (US3).

## Success Criteria

- **SC-001**: Full test suite passes; all golden files byte-identical to
  `origin/main` (this refactor must not change any emitted Turtle or
  JSON-LD).
- **SC-002**: `nix develop --quiet -c just ci` green at every commit
  (bisect-safe slices).
- **SC-003**: No module under `Cardano.Tx.*` is exposed by both
  cardano-ledger-rdf and cardano-tx-tools:tx-build.

## Out of Scope

- The `Cardano.Rdf.*` namespace migration (constitution-planned
  follow-up issue).
- Any edit to the cardano-tx-tools repository (README side of the
  policy is the sibling ticket's).
