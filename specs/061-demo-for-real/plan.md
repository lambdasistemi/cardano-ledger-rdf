# Plan — #61 demo for real

## Tech stack

- Existing `tx-graph` / `tx-view` executables (haskell.nix, GHC 9.12.3).
- `apache-jena` `arq` (already in the dev shell) for SPARQL.
- `mkdocs` + `asciinema-player` plugin (already wired in `mkdocs.yml`) for the
  doc page and embedded cast.
- Real mainnet data: the operator CBOR archive under
  `/code/amaru-treasury-tx/transactions/2026/**` for capture, reproducible by
  any operator via `--provider koios` or `--provider blockfrost --token …`.

## Approach

1. **FR-2** — grow `Cardano.Tx.View.Turtle`: add `[`/`]` lexer tokens, parse a
   bracket subject (`parseAnonSubject`) into a statement-unique synthetic
   bnode, attaching both bracket-internal and trailing predicates. Surgical,
   not a rdf4h swap.
3. **FR-3** — make `tx-view`'s `--graph` optional; `-` → `BS.hGetContents
   stdin`; `Nothing` → helpful exit-2 usage error.
4. **FR-4** — `Cardano.Tx.View.CliTree.entityMap` + `resolveAddressLabel` +
   `resolveIdentifierLabel` must key on IRI identifiers, not only blank-node
   tails. Regenerate the two affected cli-tree goldens (assets now resolve to
   `meme`/`usdm`).
5. **FR-5/6** — build the lattice (overlay once + per-tx bodies), author two
   `.rq` queries (per-scope USDM, cross-tx spend graph), run with `arq`,
   capture real output, write `docs/demo.md`, record the cast, wire nav.

## Testing

- Pure `renderView`-level specs for FR-2 (`TurtleSpec`) and FR-4
  (`CliTreeEntitySpec`).
- Exe-level spec for FR-3 (`TxViewStdinSpec`), reusing the `TX_VIEW_EXE`
  harness; case (2) also exercises FR-2's `[]` form over the pipe.
- Full `just unit` + the flake checks remain green; case-study queries
  unchanged.

## Risks

- Koios rate-limits (HTTP 429) without a token → capture from the local CBOR
  archive / a Blockfrost project-id; the documented provider loops reproduce
  the same confirmed-tx CBOR.
- Golden churn from FR-4 — mitigated by regenerating only the two genuinely
  improved goldens and diffing to confirm the change is label resolution.
