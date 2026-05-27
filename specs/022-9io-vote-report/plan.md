# Plan — 9-IO vote case study

## Tech stack

- MkDocs (existing site infrastructure)
- Apache Jena `arq` (already used in this repo's smokes) for executing SPARQL
- Existing tx-graph binary built from main HEAD
- CBOR cache at `/tmp/io-gov-actions/cbor/` (1,688 files, fetched earlier this session)
- Optional CI self-test: a small bash script that loads the lattice and asserts the documented numbers

## Slice boundaries

Two slices.

### Slice A — re-emit lattice + reproduce findings via SPARQL

Steps:
1. Build the merged emitter (`cabal build tx-graph` inside `nix develop`).
2. Re-emit 1,688 transactions: `tx-graph --in-dir /tmp/io-gov-actions/cbor --out-dir /tmp/io-gov-actions/ttl-v2`.
3. Merge into a single Turtle file with per-file bnode renaming (the technique we used earlier; produces a ~12 MB merged TTL).
4. Run each FR-1 to FR-7 SPARQL query against the merged TTL; record the result.
5. Sanity-check the numbers against the original Python-decoded values to confirm the typed emitter is consistent.

Owned files (slice A is exploration / draft notes only — no commit yet):
- `/tmp/io-gov-actions/ttl-v2/` (transient artefacts; gitignored)
- (no repo file edits)

Gate: each documented number reproduces (`arq` results match expected).

### Slice B — write the docs page

Files:
- `docs/case-studies/2026-io-budget-vote.md` (the page)
- `mkdocs.yml` (one nav entry)
- (optional) `docs/case-studies/2026-io-budget-vote.queries/*.rq` — externalised query files referenced from the page

Each section in the page:
- Title (the question)
- Prose answer (the operator-facing finding, with the number)
- A fenced ```sparql``` block with the actual query
- Optional: link to the externalised .rq file

Gate:
- `mkdocs build` clean
- All numbers in the page match the slice A measurements
- (Optional) `./gate.sh` enforces the case-study queries via a smoke

### Slice C — optional CI self-test

A `nix build .#checks.x86_64-linux.case-study-9io` derivation that:
- Re-emits the lattice from a small fixture-of-CBORs (or uses a recorded merged TTL)
- Runs the documented SPARQL queries
- Asserts each result against a recorded expected value

Judgment call: include if the operator wants the page to remain self-verifying long after this PR merges. Skip otherwise; leave a follow-up issue.

## Risks

- **Stale CBOR cache**: the cache at `/tmp/io-gov-actions/cbor/` may have been cleared. Mitigation: detect early; re-fetch via Koios if needed.
- **Emitter still misses fields the report needs**: if the typed walker for, say, the anchor URL on a Proposal doesn't actually surface a queryable `cardano:anchorUrl` triple under `cardano:Proposal`, FR-4 fails. Mitigation: verify the goldens emitted in slice A include the anchor URL on a Proposal; if not, surface as a follow-up ticket (NOT a blocker for this PR — the page documents the gap).
- **arq merge bnode handling**: ARQ may or may not collapse the `_:hash_govactionid_…` Identifier bnodes across multiple `--data` files cleanly. Mitigation: use the merged-single-TTL approach with per-file bnode prefixing (already proven in this session).
