# Implementation Plan: Auxiliary Data Body + isValid RDF

**Branch**: `17-auxiliary-data-isvalid` | **Date**: 2026-05-28 |
**Spec**: `specs/017-auxiliary-data-isvalid/spec.md`

## Summary

Extend the existing transaction-root emitter with two Conway transaction tuple
fields that were not represented in RDF: the phase-2 `isValid` flag and the
optional auxiliary data body. Reuse the existing opaque raw-CBOR leaf pattern
for auxiliary data and add boolean literal support to the emitter IR so the
Turtle output can render `xsd:boolean` directly.

## Technical Context

**Language/Version**: Haskell, GHC 9.12.3 via haskell.nix
**Primary Dependencies**: `cardano-ledger-api`, `cardano-ledger-conway`,
`cardano-ledger-binary`, `microlens`, `hspec`
**Testing**: `just unit`, focused unit/golden tests, Nix checks
**Constraints**: deterministic Turtle byte order, Hackage-ready modules,
Spec Kit artifacts in the same slice
**Project Type**: Haskell library/CLI with golden fixtures

## Constitution Check

- Stable Vocabulary And Reproducible Graphs: new predicates/classes are
  declared in vocab and goldens are regenerated deterministically.
- Generic Core, Explicit Extensions: fields are generic Conway transaction
  fields with no Amaru-specific semantics.
- Offline Determinism: emission uses only caller-provided ledger values and
  local serialization.
- Spec-First, Test-Driven, Verified Changes: this plan pairs code with
  fixture and unit coverage plus local verification.

## Implementation Design

- Add `OBoolLit Bool` to the graph IR and render it as
  `"true"^^xsd:boolean` / `"false"^^xsd:boolean` in Turtle.
- Add `xsd:` to emitted Turtle prefixes and JSON-LD contexts; update bounded
  parsers that compare Turtle and JSON-LD outputs.
- Read `isValidTxL` and `auxDataTxL` in `projectBody`.
- Add `cardano:isValid` to the transaction subject unconditionally.
- Add `cardano:hasAuxiliaryData _:auxiliaryData1` plus a sibling
  `_:auxiliaryData1 a cardano:AuxiliaryData, cardano:OpaqueLeaf ;
  cardano:hasRawBytes "<cbor-hex>"` block only for `SJust`.
- Extend `VocabTerm`, `vocab/cardano/transactions.ttl`, and derived canonical
  vocab fixtures for the new terms.
- Add two focused golden fixtures: one metadata-bearing transaction and one
  `IsValid False` transaction.
- Add unit assertions that the emitted auxiliary raw bytes match ledger
  serialization and that the false validity flag is present.
- Regenerate goldens and verify the cascade.

## Single-Slice Rationale

The code changes are tightly coupled: both fields live in the same Conway
transaction tuple and the same transaction-root RDF block. Splitting would
force repeated golden churn and two reviews of the same serializer prefix
surface. A single bisect-safe commit keeps the full round-trip shape and
vocabulary declarations coherent.

## Risks

- Golden regeneration cascade: unconditional `isValid true` touches every
  transaction golden. Mitigation: review diffs for only that predicate on
  pre-existing metadata-free fixtures.
- Parser drift: adding `xsd:boolean` changes the emitted prefix set and the
  bounded Turtle parsers. Mitigation: update both emitter-side and view-side
  parsers in the same slice.
- Vocabulary drift: strict traceability requires the local registry and
  vendored canonical fragments to stay in sync. Mitigation: regenerate
  derived vocab and update the canonical pin fragment for the three new terms.

## Verification

1. `nix develop --quiet -c just unit`
2. `nix build .#checks.x86_64-linux.{build,unit,lint,vocab-validate,vocab-owl-smoke}`
3. `./gate.sh origin/main..HEAD`
