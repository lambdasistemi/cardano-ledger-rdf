---
description: "Task list for 062-tx-metadata-decode"
---

# Tasks: Generic transaction-metadata decoding

**Input**: Design documents from `/specs/062-tx-metadata-decode/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Goldens are REQUIRED (public Turtle output changes). Golden-first
per Constitution VI — write the expected `.ttl`, watch it fail, then implement.

**Organization**: grouped by the three user stories so each is an independently
testable increment. Paths follow the repo's existing emitter + golden layout;
confirm the exact golden directory against the current harness when adding files.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different file, no incomplete dependency)
- **[USx]**: the user story the task serves

---

## Phase 1: Setup (fixtures)

- [ ] T001 [P] Add the label-1694 CBOR fixture for tx `fe2eebc8…36aa4a` at `test/fixtures/metadata/contingency-1694.cbor`
- [ ] T002 [P] Add per-kind metadatum CBOR fixtures (integer, byte-string, text, list-of-chunks, nested-map, empty-map, no-aux) under `test/fixtures/metadata/`

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: the vocabulary + walker machinery every story needs. MUST complete before Phase 3.

- [ ] T003 Add the metadatum `VocabTerm` constructors (classes `MetadatumValue`, `MetaInt`, `MetaBytes`, `MetaText`, `MetaList`, `MetaMap`, `MetadatumEntry`, `MetadatumElement`, `MetadatumMapEntry`; properties `hasMetadatum`, `metadataLabel`, `metadatumValue`, `intValue`, `textValue`, `hasElement`, `elementIndex`, `hasEntry`, `entryIndex`, `metaKey`, `metaValue`) in `src/Cardano/Tx/Graph/Emit/Vocab.hs`
- [ ] T004 Add the `vocabIri` and `vocabCurie` case branches for every new term in `src/Cardano/Tx/Graph/Emit/Vocab.hs`
- [ ] T005 Create the pure recursive walker `src/Cardano/Tx/Graph/Emit/Metadatum.hs` — `Metadatum -> Emit Object` emitting one typed value node per kind, with deterministic path-derived blank-node names (per research D2/D5); leave per-kind bodies stubbed where a later story fills them
- [ ] T006 Wire the walker into `emitAuxiliaryDataBody` in `src/Cardano/Tx/Graph/Emit/Project.hs` — additively fold the metadata map (`Map Word64 Metadatum`, ascending label) into `cardano:hasMetadatum` edges AFTER the existing opaque-bytes triples; empty map emits no edges
- [ ] T007 [P] Document the new classes + properties (domain, range, description) in `vocab/cardano/transactions.ttl`

---

## Phase 3: User Story 1 — reach metadata contents (P1) 🎯 MVP

**Goal**: labels and scalar/nested-map values are reachable as triples.
**Independent test**: quickstart §2 SPARQL resolves `body.event` → "disburse" without CBOR.

- [ ] T008 [P] [US1] Golden (FAILING first): expected `.ttl` for the integer, text, and nested-map fixtures at `test/golden/metadata/us1-scalar-map.ttl`
- [ ] T009 [US1] Implement the `MetaInt` (`intValue`), `MetaText` (`textValue`), and `MetaMap` (`hasEntry`/`entryIndex`/`metaKey`/`metaValue`) cases in `src/Cardano/Tx/Graph/Emit/Metadatum.hs` to pass T008
- [ ] T010 [US1] Implement `MetadatumEntry` emission (`hasMetadatum`, `metadataLabel` ascending) in `Metadatum.hs`/`Project.hs`; verify reachability per quickstart §2

---

## Phase 4: User Story 2 — faithful, lossless tree (P1)

**Goal**: lists keep arity (no joining), bytes ≠ text, map keys are value nodes.
**Independent test**: a 2-chunk `description` emits a 2-element `MetaList` (SC-002).

- [ ] T011 [P] [US2] Golden (FAILING first): expected `.ttl` for the list-of-chunks (arity preserved), byte-string vs text, and non-string-key map fixtures at `test/golden/metadata/us2-faithful.ttl`
- [ ] T012 [US2] Implement the `MetaList` (`hasElement`/`elementIndex`, preserve order + arity, NO joining) and `MetaBytes` (`bytesHex`) cases in `src/Cardano/Tx/Graph/Emit/Metadatum.hs` to pass T011
- [ ] T013 [US2] Assert keys emit as full `MetadatumValue` nodes via `metaKey`, that `MetaBytes` ≠ `MetaText`, and that the chunk count equals on-chain arity (SC-002)

---

## Phase 5: User Story 3 — targetable + additive (P2)

**Goal**: select by label; existing triples unchanged; deterministic.
**Independent test**: label-1694 ASK matches the tx; pre-062 hash/raw-bytes byte-identical.

- [ ] T014 [P] [US3] Golden (FAILING first): the full label-1694 `.ttl` for tx `fe2eebc8…` at `test/golden/metadata/contingency-1694.ttl`, covering contract assertions C1–C4
- [ ] T015 [US3] Regression: assert the pre-existing `cardano:hasRawBytes` + `cardano:auxiliaryDataHash` triples for the 1694 tx are byte-identical to pre-062 (additivity, C5); update any existing aux-data goldens additively (added triples only)
- [ ] T016 [US3] Verify the label-targeting ASK (quickstart §4) matches the 1694 tx and not a metadata-free tx, and that regenerating the graph twice is byte-identical (C6 / SC-003)

---

## Phase 6: Polish & cross-cutting

- [ ] T017 [P] Edge-case goldens: no-auxiliary-data emits no `hasMetadatum`; scripts-but-empty-map emits the aux node with zero entries (`test/golden/metadata/edge-*.ttl`)
- [ ] T018 [P] Haddock on every new `Vocab` term and all `Emit/Metadatum.hs` exports (Constitution V)
- [ ] T019 [P] `fourmolu` + `hlint` + `cabal check` on the changed modules
- [ ] T020 Final verification: `nix develop --quiet -c just ci` (or `nix flake check --no-eval-cache`) — all goldens green, zero regression (Constitution VI)

---

## Dependencies & order

- **Setup** (T001–T002) → **Foundational** (T003–T007) → stories.
- **Foundational blocks all stories.** Within it: T003→T004 (same file, sequential); T005→T006 (walker before wiring); T007 [P].
- **US1** (T008–T010) is the MVP. **US2** (T011–T013) extends `Metadatum.hs` so it follows US1 (same file, not parallel across stories). **US3** (T014–T016) needs all kinds, so it follows US1+US2.
- **Polish** (T017–T020) last; T020 is the gate.

## Parallel opportunities

- T001 ∥ T002 (distinct fixtures).
- Each story's golden task ([P]) is authored in parallel with the prior story's verification, but each story's *implementation* tasks touch `Metadatum.hs` and are sequential.
- T017 ∥ T018 ∥ T019 in Polish (distinct concerns), then T020 alone.

## Implementation strategy

- **MVP = Setup + Foundational + US1** — metadata contents become queryable; already delivers the auditor win.
- **Increment 2 = US2** — faithfulness (the Principle III line: lists stay lists).
- **Increment 3 = US3** — additivity proof + label targeting, the bridge to specs 063/065.
- Golden-first throughout: the `.ttl` is written and failing before the emitter case that satisfies it.
