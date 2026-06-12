# Repository Agent Guide

## What this repo is

`cardano-ledger-rdf` turns a Cardano Conway transaction into a
deterministic RDF graph and projects that graph through packaged views.
It owns the generic `cardano:` RDF vocabulary, the body-walker that emits
it, the operator-overlay loader, CIP-57 typed datum/redeemer decode, a
SHACL pass, and packaged SPARQL/text views. The runtime is two
executables:

- **`cq-rdf`** — four composable subcommands, each a pure function with a
  narrow IO contract: `overlay` (operator YAML/Turtle → overlay TTL),
  `body` (one Conway tx CBOR or fetched txid → body TTL), `blueprint`
  (TTL → CIP-57-typed TTL), `shacl` (TTL → SHACL report, non-zero on
  violation).
- **`tx-view`** — projects a canonical Turtle graph through a packaged
  view (`cli-tree`, `asset-flow`, `entity-occurrences`, `json-ld`).

`tx-graph` is a deprecated one-release compatibility symlink that
forwards to `cq-rdf body`. Generic transaction tooling (inspect, diff,
sign, validate, load-generate) lives downstream in `cardano-tx-tools`;
this repo's boundary is graph/RDF.

## How to work here

Use `just` recipes inside `nix develop`; always pass `-O0` for dev
builds. The recipes are the source of truth (`justfile`).

- Build: `nix develop --quiet -c just build`
- Unit tests: `nix develop --quiet -c just unit`
  (filter with `just unit match="SomeSpec"`)
- Full local gate: `nix develop --quiet -c just ci`
  (build + unit + smokes + vocab gates + cabal-fmt + fourmolu + hlint)
- Flake checks: `nix flake check --no-eval-cache`
- Vocabulary gates: `just vocab-validate`, `just vocab-owl-smoke`,
  `just vocab-accessibility`
- Run the binaries without building:
  `nix run .#cq-rdf -- --help`, `nix run .#tx-view -- --help`
- Docs site: `just build-docs` (`mkdocs build --strict`) or
  `just serve-docs`

Project conventions: GHC 9.12.3 via `haskell.nix`; fourmolu with leading
commas/arrows; Haddock on all exports; cabal must stay Hackage-ready
(`cabal check`). Feature work uses Spec Kit (`specs/`,
`.specify/memory/constitution.md`); read the constitution before
planning. The `gate.sh` script is the mechanical PR gate. Do not
populate secrets from an agent session — leave `gh secret set` commands
for the operator.

## Skills

Activatable procedures live under `skills/`. Load the one whose
description matches your task.

- `skills/cardano-ledger-rdf-guide/` — how the repo is laid out, how to
  build/test/run it, where the emitter / overlay loader / views / vocab
  live, how to drive `cq-rdf` and `tx-view`, and where the answers to
  common user questions are documented.

## First-run setup

No operator-specific local config is required. `cq-rdf body --provider`
fetchers take their token via `--token` (blockfrost requires it; koios
has a free tier) — never hard-code secrets in the repo.
