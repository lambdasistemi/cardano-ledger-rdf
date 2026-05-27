# Implementation Plan: Extract Transaction RDF Surface

**Branch**: `001-extract-tx-rdf` | **Date**: 2026-05-26 | **Spec**: `spec.md`
**Input**: Feature specification from `/specs/001-extract-tx-rdf/spec.md`

## Summary

Additively migrate the transaction RDF surface from `cardano-tx-tools` into
`cardano-rdf`: source, executables, tests, fixtures, rules, SPARQL views, docs,
Nix, CI, and operator notes. Verify the new repo works, then stop before any
old source deletion.

## Technical Context

**Language/Version**: Haskell, GHC 9.12.3 via haskell.nix  
**Primary Dependencies**: Cardano ledger packages, optparse-applicative,
aeson, yaml, http-client-tls, MkDocs Material  
**Storage**: Filesystem fixtures, CBOR inputs, Turtle/JSON-LD outputs  
**Testing**: Hspec/golden tests, cabal check, fourmolu, hlint, MkDocs strict  
**Target Platform**: Linux CI on `nixos`; Darwin build support retained from
source where practical  
**Project Type**: Haskell library/CLI plus documentation site  
**Performance Goals**: Preserve existing byte-stable graph emission; no new
runtime performance target in this migration  
**Constraints**: No deletion in `/code/cardano-tx-tools`; no live secret
required for verification; networked fetch remains explicit  
**Scale/Scope**: Existing tx-graph/tx-fetch/tx-view code, fixtures, docs, and
support modules required to build them

## Constitution Check

- **RDF product boundary**: PASS. The target repo is `cardano-rdf`; tx-tools is
  treated as the old source and future downstream consumer.
- **Vocabulary stability**: PASS. Existing TTL fixtures and vocab pins move with
  tests; any drift fails goldens.
- **Generic core boundary**: PASS WITH DEBT. Amaru appears in fixtures and docs
  as canary material. Existing module names may remain `Cardano.Tx.*` in this
  first copy; namespace cleanup must be recorded as follow-up debt.
- **Offline/network split**: PASS. `tx-graph` and `tx-view` stay pure/offline;
  `tx-fetch` remains explicit Blockfrost-compatible network IO.
- **Docs move with code**: PASS. Move docs, views, rules, scripts, fixtures, and
  prior-art pages with source.
- **Test-first verification**: PASS. Existing tests/goldens are the regression
  suite; final gate runs build/tests/docs.
- **No premature deletion**: PASS. Do not edit old repo except status checks.

## Project Structure

### Documentation (this feature)

```text
specs/001-extract-tx-rdf/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (repository root)

```text
app/
├── tx-graph/
├── tx-fetch/
└── tx-view/

src/Cardano/Tx/
├── Graph/
├── View/
└── support modules needed by the migrated graph pipeline

test/
├── Cardano/Tx/Graph/
├── Cardano/Tx/View/
└── fixtures/

docs/
rules/
views/
nix/
.github/workflows/
```

**Structure Decision**: Preserve the proven source layout for the first working
copy so verification can distinguish migration damage from intentional
refactors. Namespace/package tightening is a follow-up after the additive copy
passes.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Retain some `Cardano.Tx.*` names initially | Keeps the copy buildable and testable before deleting old source | Immediate API-name churn would combine extraction with a broad API break and obscure regressions |
| Copy support modules beyond `Graph`/`View` | Graph code imports blueprint, diff, resolver, ledger, and fixture helpers | Hand-stubbing support would not prove the real RDF engine works |

## Phases

1. Repository bootstrap: GitHub repo, constitution, labels, workflow
   permissions, docs/secrets note.
2. Additive migration copy: source, tests, fixtures, docs, rules, views, Nix,
   CI.
3. Metadata adaptation: README/site/repo references to `cardano-rdf`; retain
   historical links only where intentional.
4. Verification: build, tests, docs, cabal check, old-repo no-deletion check.
5. Stop point: report evidence and do not remove old source.
