# Implementation Plan: Typed metadata schemas

**Branch**: `063-typed-metadata-schemas` | **Date**: 2026-06-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/063-typed-metadata-schemas/spec.md`

## Summary

Add a `cq-rdf metadata --schemas DIR` pipeline pass that reads the generic
`cardano:` metadatum tree (spec 062), and for every metadata label with a
registered operator schema, projects typed predicates into an explicit
extension namespace — additively, mirroring how `cq-rdf blueprint` typed-
decodes datums. The pass reuses the existing custom Turtle machinery
(`parseCanonicalTurtle` → `TurtleGraph` block map → text-append with
idempotency) rather than a new RDF library. The worked schema is the
SundaeSwap/Amaru label 1694, projecting `treasury:event`, `treasury:label`,
`treasury:justification` (chunk-joined), `treasury:references`,
`treasury:registryInstance`, and `treasury:destination`. This delivers the
two primitives spec 065's hygiene shapes need: `registryInstance` verbatim
and a label target marker.

## Technical Context

**Language/Version**: Haskell, GHC 9.12.3 (`haskell.nix`, `ghc9123`)  
**Primary Dependencies**: the in-repo custom Turtle pass in `app/tx-graph/Main.hs` (`parseCanonicalTurtle`, `TurtleGraph`, `objectFor`/`literalFor`, the enrich-append pattern from `enrichBlueprintTurtle`); `aeson` (schema JSON, like `*.cip57.json` blueprints); `text`, `bytestring`. Reads the `cardano:` metadatum tree from 062.  
**Storage**: N/A — pure stdin-Turtle → stdout-Turtle transform over local schema files  
**Testing**: golden Turtle fixtures + unit, via `just ci` / `nix flake check --no-eval-cache`  
**Target Platform**: Linux/Darwin; `cq-rdf` CLI  
**Project Type**: library + CLI pass inside `cardano-ledger-rdf`  
**Performance Goals**: linear in the metadatum tree; bounded by metadata size  
**Constraints**: offline; **byte-stable deterministic Turtle**; **generic engine, no business semantics in core** (Principle III)  
**Scale/Scope**: one new subcommand + a schema loader + a tree-walking projector + the `treasury:` typed terms + the 1694 schema asset + goldens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Repository boundary**: ✅ A generic pipeline pass in the core (the engine), plus an explicit extension (the 1694 schema asset + `treasury:` terms). No `cardano-tx-tools` app reintroduced.
- **Deterministic RDF**: ✅ Additive append with idempotency (the blueprint pattern); stable field order + subject naming; new goldens + `treasury:` ontology docs.
- **Generic core**: ✅ The engine applies *any* schema and knows no label meaning. The 1694 schema and the `treasury:` namespace are the explicit extension (FR-010). Amaru is the canary fixture.
- **Offline/network boundary**: ✅ N/A — reads stdin Turtle + local schema files.
- **Hackage-ready Haskell**: ✅ Haddock on new modules/terms; `cabal check`, fourmolu/hlint, Nix gates stay green.
- **Spec/test/verification**: ✅ Golden-first: write the expected typed `.ttl` for the 1694 fixture, watch it fail, then implement.
- **Migration deletion stop**: ✅ Additive; nothing deleted.

No violations → Complexity Tracking empty. **Note:** the `treasury:` namespace has **no** strict `VocabTraceabilitySpec` gate (that is `cardano:`-only), so 063 avoids the pin/allowlist friction that 062 hit.

## Project Structure

### Documentation (this feature)

```text
specs/063-typed-metadata-schemas/
├── plan.md
├── research.md          # Phase 0 — subcommand-vs-mode, schema format, tree-paths, joining, error marker
├── data-model.md        # Phase 1 — the schema entity + the treasury: typed terms
├── quickstart.md        # Phase 1 — run the pass, query treasury:event / registryInstance
├── contracts/
│   └── metadata-schema-contract.md   # schema JSON format + 1694 schema + expected typed output
└── tasks.md             # Phase 2 (/speckit.tasks)
```

### Source Code (repository root)

```text
app/tx-graph/Main.hs            # add: CmdMetadata variant, metadataOptionsParser (--schemas DIR),
                                #   `metadata` subcommand, metadataCommand (stdin TTL ->
                                #   loadMetadataSchemaDirectory -> enrichMetadataTurtle -> stdout)
src/Cardano/Tx/Metadata/Schema.hs   # NEW — schema type + JSON loader (*.schema.json)
src/Cardano/Tx/Metadata/Project.hs  # NEW — walk the cardano: metadatum tree per schema,
                                    #   emit typed extension triples (reuses parseCanonicalTurtle,
                                    #   objectFor/literalFor; joined-text; schema-error on mismatch)
vocab/treasury/overlay.ttl      # add typed metadata terms (event, label, justification,
                                #   references, registryInstance, destination, schemaError)
docs/case-studies/2026-05-amaru-treasury/schemas/treasury-1694.schema.json   # the worked schema asset
test/                           # 1694 typed-projection golden + per-kind/edge goldens
```

**Structure Decision**: A dedicated `cq-rdf metadata` subcommand (not a `blueprint` mode) — blueprint keys by **script hash** on datum/redeemer blocks; metadata keys by **integer label** on the aux node. Different input, different keying → a sibling pass keeps the pipeline legible (`overlay | body | blueprint | metadata | shacl`). The pass reuses blueprint's proven Turtle plumbing (`parseCanonicalTurtle`, `objectFor`/`literalFor`, append-with-idempotency) so it is a small, well-trodden addition, with the schema-walk isolated in two new `Cardano.Tx.Metadata.*` modules.

## Complexity Tracking

> No Constitution Check violations — section intentionally empty.
