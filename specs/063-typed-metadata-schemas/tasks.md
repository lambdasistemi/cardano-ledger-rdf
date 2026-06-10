---
description: "Task list for 063-typed-metadata-schemas"
---

# Tasks: Typed metadata schemas

**Input**: Design documents from `/specs/063-typed-metadata-schemas/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Goldens are REQUIRED (public Turtle output). Golden-first per
Constitution VI — write the expected typed `.ttl`, watch it fail, then implement.
The `treasury:` namespace has NO strict traceability gate (that is `cardano:`-only),
so vocab additions here are low-friction.

**Organization**: grouped by the three user stories; each is an independently
testable increment.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup (fixtures)

- [ ] T001 [P] Add the label-1694 schema asset `treasury-1694.schema.json` (per data-model.md) under `docs/case-studies/2026-05-amaru-treasury/schemas/`
- [ ] T002 [P] Add input metadata-graph fixtures (the `cq-rdf body`-emitted `.ttl` carrying the 062 `cardano:` metadatum tree) under `test/fixtures/metadata-typed/`: the contingency-1694 graph + small per-kind/edge cases (text, int, bytes, list-of-chunks, nested-map, no-1694, missing-key)

---

## Phase 2: Foundational (blocking prerequisites)

- [ ] T003 Add the typed `treasury:` terms (`event`, `label`, `justification`, `references`, `registryInstance`, `destination`, `schemaError`) with domain/range/description to `vocab/treasury/overlay.ttl`
- [ ] T004 Create `src/Cardano/Tx/Metadata/Schema.hs` — the schema type + `*.schema.json` loader (`label`, `prefix`, `namespace`, `fields[{predicate,path,kind}]`); `MetadataSchemaParseError` on malformed, mirroring `BlueprintParseError`
- [ ] T005 Create `src/Cardano/Tx/Metadata/Project.hs` — the projector skeleton; REUSE the blueprint plumbing (`parseCanonicalTurtle`, `objectFor`/`literalFor`, the append-with-idempotency pattern from `enrichBlueprintTurtle`); walk `cardano:hasMetadatum` → `metadataLabel` match → `metadatumValue` → `MetaMap` by `metaKey`/`textValue` path; emit typed triples on the **transaction subject**, additive + idempotent
- [ ] T006 Wire the CLI in `app/tx-graph/Main.hs`: `CmdMetadata` + `metadataOptionsParser` (`--schemas DIR`) + the `metadata` subcommand + `metadataCommand` (stdin TTL → `loadMetadataSchemaDirectory` → `enrichMetadataTurtle` → stdout); register the new modules in `cardano-ledger-rdf.cabal`
- [ ] T007 [P] Document the new `treasury:` terms in `vocab/treasury/overlay.ttl` (and any docs mirror)

---

## Phase 3: User Story 1 — read by typed name (P1) 🎯 MVP

**Goal**: scalar + nested-map fields project to one-hop typed predicates.
**Independent test**: quickstart §2 resolves `treasury:event` → "disburse" with no tree-walk.

- [ ] T008 [P] [US1] Golden (FAILING first): expected typed `.ttl` for `text`/`int`/`bytes` + nested-map path projection (`event`, `label`, `registryInstance`) at `test/fixtures/metadata-typed/us1-scalar-map.ttl`
- [ ] T009 [US1] Implement the `text`/`int`/`bytes` kinds + descend-by-map-key path navigation (`metaKey`/`textValue` match → `metaValue`) in `Project.hs` to pass T008
- [ ] T010 [US1] Implement label matching (`metadataLabel` → schema) + typed-predicate emission on the tx subject; verify reachability per quickstart §2

---

## Phase 4: User Story 2 — faithful, lossless join (P1)

**Goal**: `joinedText`/`uriList` kinds; the generic tree stays intact.
**Independent test**: a multi-chunk `justification` projects to one joined string while its `cardano:MetaList` remains (SC-002).

- [ ] T011 [P] [US2] Golden (FAILING first): `joinedText` (multi-chunk `justification`) + `uriList` (`references`) + additivity at `test/fixtures/metadata-typed/us2-faithful.ttl`
- [ ] T012 [US2] Implement `joinedText` (in-order concat of a `MetaList` of `MetaText` by `elementIndex`) and `uriList` kinds in `Project.hs` to pass T011
- [ ] T013 [US2] Assert the joined value equals the in-order concatenation AND the generic `cardano:MetaList` is byte-identical/unchanged (FR-004, SC-002, SC-005)

---

## Phase 5: User Story 3 — targeting + registry + errors (P2)

**Goal**: full 1694 projection, schema-error on mismatch, the two 065 primitives.
**Independent test**: select the tx by `treasury:event`; read `registryInstance` verbatim.

- [ ] T014 [P] [US3] Golden (FAILING first): full label-1694 typed projection for the contingency tx (contract C1–C4) + `schemaError` edge cases at `test/fixtures/metadata-typed/contingency-1694.ttl`
- [ ] T015 [US3] Implement schema-mismatch → `<prefix>:schemaError "<msg>"` (research D6; generic tree intact) + the `MetadataSchemaParseError` abort path
- [ ] T016 [US3] Verify: label-targeting (`treasury:event` selects the 1694 tx, not a metadata-free tx, C5), `registryInstance` verbatim (C2), and byte-identical re-run (C6 / SC-004)

---

## Phase 6: Polish & cross-cutting

- [ ] T017 [P] Edge goldens: no registered schema → no `treasury:*` output; missing `body/event` → `schemaError`, NOT a partial projection
- [ ] T018 [P] Haddock on `Schema.hs` / `Project.hs` exports + the new `treasury:` terms; `fourmolu` + `hlint` + `cabal check`
- [ ] T019 Final verification: `nix develop --quiet -c just ci` — all goldens green, zero regression on existing fixtures

---

## Dependencies & order

- **Setup** (T001–T002) → **Foundational** (T003–T007) → stories.
- Foundational blocks all stories. T004→T005→T006 (loader → projector → wiring); T003/T007 [P].
- **US1** (T008–T010) is the MVP. **US2** (T011–T013) extends `Project.hs` → follows US1 (same file). **US3** (T014–T016) needs all kinds + errors → follows US1+US2.
- **Polish** (T017–T019) last; T019 is the gate.

## Parallel opportunities

- T001 ∥ T002 (distinct fixtures); each story's golden ([P]) authored ahead, but the `Project.hs` implementation tasks are sequential.
- T017 ∥ T018 in Polish, then T019 alone.

## Implementation strategy

- **MVP = Setup + Foundational + US1** — typed fields become one-hop queryable; already the auditor win.
- **Increment 2 = US2** — the chunk-join 062 deferred, additively.
- **Increment 3 = US3** — the registry-instance + label-targeting primitives that unblock spec 065's hygiene shapes.
- Golden-first throughout: the typed `.ttl` is written and failing before the projector case that satisfies it.

## Commit shape

Conventional Commits, bisect-safe, one commit per phase, `Tasks: T063-(F|S1|S2|S3|P)`
trailers (F = setup+foundational, S1/S2/S3 = the stories, P = polish). Do not push.
