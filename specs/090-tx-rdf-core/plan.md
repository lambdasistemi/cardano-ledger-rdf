# Implementation Plan: tx-rdf-core package split

**Branch**: `rdf-90-tx-rdf-core` | **Date**: 2026-06-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/090-tx-rdf-core/spec.md`

## Summary

Split the current single `cardano-ledger-rdf` Cabal library into a lean
`tx-rdf-core` library plus the existing fat library/executables. Preserve
module names and behavior, move only package ownership/dependencies, and prove
the pure package excludes network, YAML, optparse, directory, filepath, and
process dependencies.

## Technical Context

**Language/Version**: Haskell GHC 9.12.3  
**Primary Dependencies**: cardano-ledger packages, plutus packages,
bytestring, text, containers, aeson, Cabal, Nix/haskell.nix  
**Storage**: N/A  
**Testing**: hspec/golden tests through `just unit`; local gate through
`just ci`; Nix package builds through `nix build`  
**Target Platform**: Hackage-ready Haskell libraries and CLI executables;
`tx-rdf-core` must stay wasm-compile friendly  
**Project Type**: Multi-package Haskell library plus CLI executables  
**Performance Goals**: No behavior or output change; package split should not
add runtime work to emit or view paths  
**Constraints**: Core dependency closure must exclude HTTP/YAML/optparse and
filesystem/process IO packages; no network fallback in pure flows  
**Scale/Scope**: One repository, two packages, existing module namespace

## Constitution Check

- **Repository boundary**: Pass. The split is inside the generic Cardano RDF
  repository and does not add downstream transaction tooling.
- **Deterministic RDF**: Pass. No triple shape or vocabulary changes are
  planned; emit goldens must stay byte-identical.
- **Generic core**: Pass. Core package keeps Cardano transaction/RDF concepts;
  no Amaru business semantics move into core.
- **Offline/network boundary**: Pass. HTTP providers and Web2 resolution stay
  in the fat package; core remains offline.
- **Hackage-ready Haskell**: Pass. Both packages need metadata, bounded
  dependencies, explicit modules, formatting, linting, and `cabal check`.
- **Spec/test/verification**: Pass. Add package-boundary proof and run existing
  golden/unit gates.
- **Migration deletion stop**: Pass. No downstream deletion is in scope.

## Module Classification

Requested scan:

```sh
grep -rE "Network|HTTP|Yaml|Optparse|System.(IO|Process|Directory)" src app test --include='*.hs'
```

### Core candidates

- `src/Cardano/Tx/Blueprint.hs`
- `src/Cardano/Tx/Decode.hs`
- `src/Cardano/Tx/Graph/Emit.hs`
- `src/Cardano/Tx/Graph/Emit/**`
- `src/Cardano/Tx/Graph/Rules/Load/Parse/Turtle.hs`
- `src/Cardano/Tx/Graph/Rules/Load/Types.hs`
- `src/Cardano/Tx/View.hs`
- `src/Cardano/Tx/View/**`

### Fat package modules

- `src/Cardano/Tx/Graph/Provider.hs` uses HTTP.
- `src/Cardano/Tx/Graph/Resolve/Web2.hs` uses HTTP.
- `src/Cardano/Tx/Graph/Resolve.hs` stays fat unless the driver proves it is
  needed by core and has no fat deps.
- `src/Cardano/Tx/Graph/Rules/Load.hs` currently re-exports YAML/import IO and
  must be split or kept fat.
- `src/Cardano/Tx/Graph/Rules/Load/Parse/Yaml.hs` uses libyaml/yaml.
- `src/Cardano/Tx/Graph/Rules/Load/Resolve/Imports.hs` uses filesystem IO and
  YAML.
- `app/tx-graph/Main.hs` and `app/tx-view/Main.hs` use optparse/system IO and
  stay executable/fat.

### Known design pressure

Some emit modules import `Cardano.Tx.Graph.Rules.Load` for `EntityDecl` and
`LeafType`. The driver should move or expose the pure rule types/import map
from `tx-rdf-core` without dragging YAML/import IO into the core package.

## Project Structure

```text
cardano-ledger-rdf.cabal        # multi-package metadata or package split wiring
cabal.project                   # includes both local packages if needed
src/                            # existing fat package source tree, adjusted as needed
tx-rdf-core/src/                # acceptable if the driver chooses physical split
app/tx-graph/Main.hs            # cq-rdf executable remains fat
app/tx-view/Main.hs             # tx-view executable remains fat
test/                           # existing suite plus package-boundary checks
specs/090-tx-rdf-core/          # spec, plan, tasks, worker evidence
```

**Structure Decision**: Keep public `Cardano.Tx.*` module names. Prefer the
smallest Cabal/package layout that makes `tx-rdf-core` build standalone with a
lean closure and keeps existing executables unchanged.

## Verification Plan

- `nix develop --quiet -c cabal build tx-rdf-core:lib:tx-rdf-core -O0`
- Dependency proof for `tx-rdf-core` showing no
  `http-client`, `http-client-tls`, `libyaml`, `yaml`,
  `optparse-applicative`, `directory`, `filepath`, or `process`.
- `nix develop --quiet -c cabal build all -O0`
- `nix develop --quiet -c just unit`
- Golden byte-identity check through the existing emit golden tests:
  `test/Cardano/Tx/Graph/EmitGoldenSpec.hs`,
  `test/Cardano/Tx/Graph/Emit/ReproducibilitySpec.hs`, and the full
  `test/fixtures/tx-graph/**/expected*.ttl` fixture comparisons exercised by
  `just unit`.
- `nix build`
- `nix develop --quiet -c just ci`
- Inspector CHaP pin dated 2026-04-15 for `tx-rdf-core`; Q-file if incompatible.

## Complexity Tracking

No constitution violations are planned.
