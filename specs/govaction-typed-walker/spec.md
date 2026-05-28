# Spec — Typed governance-action walker

Closes [#5](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/5), [#6](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/6), [#7](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/7).

## Why

The proposal cluster already exposes proposal shell fields and the `TreasuryWithdrawals` action as typed RDF. The remaining Conway governance-action constructors still fall back to opaque CBOR, which forces consumers to decode ledger bytes before they can query protocol-parameter changes, committee updates, constitutions, or hard-fork targets.

## User Story

As an operator querying a transaction RDF lattice, I want `ParameterChange`, `UpdateCommittee`, `NewConstitution`, and `HardForkInitiation` proposal actions to emit typed subjects and predicates so governance analytics can use SPARQL directly without a side-channel CBOR decoder.

## Functional Requirements

- **FR-1 — Parameter change.** `ParameterChange` actions MUST emit a typed action block linked from the proposal with `cardano:hasGovAction`, an optional `cardano:hasPriorAction`, a typed `cardano:ProtocolParamUpdate` child, and an optional guard policy hash.
- **FR-2 — Protocol parameters.** The protocol-parameter update walker MUST emit every present Conway parameter field with a stable `cardano:` predicate and typed sub-blocks for execution-unit prices, execution-unit limits, and voting thresholds.
- **FR-3 — Committee update.** `UpdateCommittee` actions MUST emit optional prior action, removed member credentials, added member entries with term limits, and the new quorum.
- **FR-4 — Constitution and hard fork.** `NewConstitution` actions MUST emit prior action, constitution anchor, and optional guardrail script; `HardForkInitiation` actions MUST emit prior action and protocol-version major/minor fields.
- **FR-5 — Existing behavior.** `TreasuryWithdrawals`, `NoConfidence`, and `InfoAction` behavior MUST remain unchanged, and the raw governance-action bytes fallback MUST remain available.
- **FR-6 — Vocabulary and fixtures.** All emitted classes and predicates MUST be declared in the repository vocabulary and canonical pin, with golden fixtures covering the four newly typed action constructors.

## Success Criteria

- `nix develop -c just unit` is green.
- `nix build .#checks.x86_64-linux.{build,unit,lint,vocab-validate,vocab-owl-smoke}` is green.
- `./gate.sh origin/main..HEAD` accepts the final commit shape.
