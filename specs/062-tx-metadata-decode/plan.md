# Implementation Plan: Generic transaction-metadata decoding

**Branch**: `062-tx-metadata-decode` | **Date**: 2026-06-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/062-tx-metadata-decode/spec.md`

## Summary

Decode the Conway auxiliary-data **transaction-metadata map**
(`Map Word64 Metadatum`) into a faithful, generic `cardano:` RDF value
tree, additively alongside the existing opaque-CBOR and hash triples.
Each top-level label becomes a metadatum entry; each value is decoded
into one of five typed nodes (integer / byte-string / text-string /
list / map), preserving order, arity, and chunking. No label-specific or
treasury interpretation is performed here — that is spec 063. The change
is localized to the auxiliary-data emitter (`emitAuxiliaryDataBody` in
`src/Cardano/Tx/Graph/Emit/Project.hs`) plus new `cardano:` vocabulary
terms and goldens, with the real label-1694 block from tx `fe2eebc8…` as
the headline fixture.

## Technical Context

**Language/Version**: Haskell, GHC 9.12.3 (`haskell.nix`, `ghc9123`)  
**Primary Dependencies**: `cardano-ledger-core` (`TxAuxData ConwayEra`), `Cardano.Ledger.Metadata` (`Metadatum(..)`), the in-repo Emit DSL (`Cardano.Tx.Graph.Emit.*`: `Triple`/`Subject`/`Object`/`tellTriple`/`vocabCurie`/`BnodeName`), `bytestring`, `text`  
**Storage**: N/A — pure emission over the already-decoded `TxAuxData` value  
**Testing**: golden Turtle fixtures + unit tests via the repo suite (`just ci` / `nix flake check --no-eval-cache`)  
**Target Platform**: Linux/Darwin; `cq-rdf` library + CLI  
**Project Type**: library (RDF emitter) inside `cardano-ledger-rdf`  
**Performance Goals**: linear in metadatum-tree size; metadata is bounded (~16 KB/tx), no dedicated perf target  
**Constraints**: offline; **byte-stable deterministic Turtle**; **generic core only** (no per-label semantics)  
**Scale/Scope**: one emitter function extended + one recursive walker + N new vocab terms + goldens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Repository boundary**: ✅ Generic Cardano RDF core (the body/aux-data emitter). No `cardano-tx-tools` application reintroduced.
- **Deterministic RDF**: ✅ Plan identifies the vocabulary impact (new metadatum classes/properties), the new + updated goldens, the `transactions.ttl` doc additions, and stable subject naming + entry/element ordering (FR-007).
- **Generic core**: ✅ Only `cardano:` terms; **no** label-1694/treasury interpretation (FR-008). Amaru tx appears only as a fixture.
- **Offline/network boundary**: ✅ N/A — operates on caller-provided CBOR; adds no fetcher.
- **Hackage-ready Haskell**: ✅ New vocab constructors carry Haddock; `cabal check`, fourmolu/hlint, and Nix gates stay green.
- **Spec/test/verification**: ✅ Golden-first — write the expected `.ttl` for the 1694 fixture (and per-kind goldens), watch them fail, then implement.
- **Migration deletion stop**: ✅ Additive; no old source deleted.

No violations → Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/062-tx-metadata-decode/
├── plan.md              # this file
├── research.md          # Phase 0 — decisions (value-tree shape, ordering, naming)
├── data-model.md        # Phase 1 — the metadatum vocabulary
├── quickstart.md        # Phase 1 — decode + query the 1694 metadata
├── contracts/
│   └── metadata-graph-contract.md   # the emitted-triple contract per kind
└── tasks.md             # Phase 2 (/speckit.tasks — not created here)
```

### Source Code (repository root)

```text
src/Cardano/Tx/Graph/Emit/
├── Project.hs        # extend emitAuxiliaryDataBody: after the opaque-bytes
│                     #   triples, walk the metadata map and emit the value tree
├── Metadatum.hs      # NEW — pure recursive Metadatum → [Triple] walker
│                     #   (keeps Project.hs lean; one node per kind)
└── Vocab.hs          # add VocabTerm constructors + vocabIri + vocabCurie cases
                      #   for the metadatum classes/properties

vocab/cardano/
└── transactions.ttl  # document the new classes + properties (Principle II)

test/                 # add the 1694 tx CBOR fixture + expected golden .ttl,
                      #   plus per-kind (int/bytes/text/list/map) golden cases
```

**Structure Decision**: Single library. The recursive walk lives in a new
focused `Cardano.Tx.Graph.Emit.Metadatum` module (a pure
`Metadatum -> Emit Object` / `-> [Triple]` function) so `Project.hs` only
gains a few lines wiring it into `emitAuxiliaryDataBody`; vocabulary terms
extend the existing `Vocab.hs` enum, keeping one source of truth for IRIs
and CURIEs.

## Complexity Tracking

> No Constitution Check violations — section intentionally empty.
