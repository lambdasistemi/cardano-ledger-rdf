# Implementation Plan: Body Treasury Value And Donation RDF

**Branch**: `014-body-treasury-donation` | **Date**: 2026-05-28 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/014-body-treasury-donation/spec.md`

## Summary

Add two additive transaction body predicates for Conway fields 21 and 22. The existing body-root emitter already handles scalar optional fields on the `_:tx` subject, so this slice extends that shape without a new module or sub-bnode.

## Technical Context

**Language/Version**: Haskell, GHC 9.12.3 via Nix
**Primary Dependencies**: `cardano-ledger-api`, `cardano-ledger-conway`, existing RDF emitter modules
**Storage**: N/A
**Testing**: Hspec unit tests and tx-graph Turtle goldens
**Target Platform**: Linux/Nix development and CI
**Project Type**: Haskell library and CLI repository
**Performance Goals**: No measurable runtime impact beyond two optional lens reads
**Constraints**: Deterministic Turtle byte order and byte-stable existing fixtures
**Scale/Scope**: One bisect-safe slice touching emitter, vocab, fixtures, tests, and gate

## Constitution Check

- **Repository boundary**: Generic Cardano RDF core transaction graph emitter.
- **Deterministic RDF**: Predicate order is fixed in `emitTxBlock`; new predicates are inserted without reshuffling existing emitted triples.
- **Generic core**: The fields are ledger transaction body semantics, not Amaru treasury business logic.
- **Offline/network boundary**: Pure graph emission remains offline.
- **Hackage-ready Haskell**: No new exported module; formatting, unit tests, lint, vocabulary validation, OWL smoke, and build gates must pass.
- **Spec/test/verification**: Body-root tests and golden fixtures are written before production implementation; final verification uses the worker brief commands.
- **Migration deletion stop**: No old source deletion.

## Project Structure

### Documentation (this feature)

```text
specs/014-body-treasury-donation/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (repository root)

```text
src/Cardano/Tx/Graph/Emit/
├── Project.hs
└── Vocab.hs

vocab/cardano/
└── transactions.ttl

test/Cardano/Tx/Graph/Emit/
├── BodyRootSpec.hs
└── VocabTraceabilitySpec.hs

test/fixtures/tx-graph/
├── Fixtures/TxGraph/S27_CurrentTreasuryValue.hs
├── Fixtures/TxGraph/S28_Donation.hs
├── 27-current-treasury-value/
└── 28-donation/
```

**Structure Decision**: Reuse the existing transaction graph emitter, body-root spec, and fixture/golden layout.

## Complexity Tracking

No constitution violations.

## Risks

- The ledger exposes donation as `Coin` rather than `StrictMaybe Coin`; zero must be treated as absent to preserve sparse CBOR map semantics.
- Canonical vocabulary traceability must include the new predicate declarations in both the local vocabulary and vendored canonical fixture.

## Single-Slice Rationale

The change is additive, has two closely related scalar body fields, and can be validated with one focused test/golden set. Splitting would create intermediate states where either code or vocabulary traceability is incomplete.
