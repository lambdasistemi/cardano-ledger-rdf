# Implementation Plan: tx-graph Single-CBOR Surface

**Branch**: `059-tx-graph-simplify`
**Spec**: `specs/059-tx-graph-simplify/spec.md`

## Technical Context

**Language/Version**: Haskell, GHC 9.12.3 via `haskell.nix`
**Primary Dependencies**: `optparse-applicative`, Cardano ledger packages,
Apache Jena `arq` for empirical verification
**Testing**: Hspec unit/golden tests, case-study `arq` runs, Nix checks,
MkDocs strict build, `gate.sh`
**Project Type**: Haskell library plus CLI executables and documentation

## Constitution Check

- Stable vocabulary and reproducible graphs: PASS. The CLI surface changes,
  while emitted triple shapes remain deterministic.
- Offline determinism and explicit network boundaries: PASS. `tx-graph`
  remains a pure local CBOR-to-RDF transformation; case-study fetchers are
  explicit pipeline steps.
- Spec-first and verified changes: PASS. This scaffold records the requested
  implementation and empirical comparison workflow.
- Migration without premature deletion: PASS. No source is deleted from
  downstream repositories.

## Removal Scope

- Delete `--in-dir` and `--out-dir` parser fields and dispatch branches from
  `app/tx-graph/Main.hs`.
- Reject multiple positional CBOR inputs.
- Keep standalone overlay emission (`--rules FILE` with no input).
- Keep `--out FILE` as a stdout alternative for single-input mode.
- Keep `renderLatticeTurtle` available internally for tests and library users;
  remove only the executable's batch-mode path.

## Golden Strategy

CLI batch fixtures are not part of the unit goldens. Transaction RDF goldens
remain byte-stable except where the empirical pass exposed an invalid
GovActionId prior-action IRI; those goldens are regenerated from the harness.

## Case-Study Verification Methodology

1. Build the pre-change executable with the batch CLI still present.
2. Emit each case-study lattice with the old batch mode.
3. Extract every fenced `sparql` block from `queries/q*.md` and run it with
   `arq --data lattice.ttl --query block.rq`.
4. Save row counts and stdout hashes as the baseline.
5. Switch pipelines to overlay-once plus `for f in cbor/*.cbor; do tx-graph "$f"; done`.
6. Rebuild, re-emit each lattice, rerun the same extracted queries.
7. Compare row counts and stdout hashes per query; any mismatch blocks the
   commit.

## Risks

- Existing case-study docs may contain illustrative fenced SPARQL. These must
  be made executable because the acceptance gate treats fenced blocks as the
  query contract.
- The treasury pipeline requires Blockfrost credentials for fetch; in an agent
  session without secrets, reuse fetched CBORs or fetch equivalent CBORs from
  a public endpoint while keeping the pipeline itself credential-safe.
