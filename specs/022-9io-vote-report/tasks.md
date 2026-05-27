# Tasks — 9-IO vote case study

## Slice A — re-emit lattice + verify SPARQL queries

- [X] T022-S1 — build tx-graph from current main (`cabal build tx-graph` in `nix develop`)
- [X] T022-S1 — verify `/tmp/io-gov-actions/cbor/` is intact (1,688 files); if not, re-fetch via Koios
- [X] T022-S1 — `tx-graph --in-dir /tmp/io-gov-actions/cbor --out-dir /tmp/io-gov-actions/ttl-v2` (re-emit using merged emitter)
- [X] T022-S1 — merge into a single Turtle via per-file bnode prefixing (the script we used earlier)
- [X] T022-S1 — write+run query FR-1 (asks per proposal); verify total = ₳162,145,961
- [X] T022-S1 — write+run query FR-2 (single beneficiary stake hash)
- [X] T022-S1 — write+run query FR-3 (single guard policy script hash)
- [X] T022-S1 — write+run query FR-4 (proposer anchor URLs per proposal)
- [X] T022-S1 — write+run query FR-5 (tallies per proposal, via typed GovActionId join)
- [X] T022-S1 — write+run query FR-6 (bloc + swing voters)
- [X] T022-S1 — write+run query FR-7 (rationale-anchor host distribution)
- [X] T022-S1 — record each result in WIP.md for cross-referencing in slice B
- [X] T022-S1 — commit: `docs(case-study): verified SPARQL queries for 9-IO vote process (slice A draft)` with `Tasks: T022-S1`. NB this commit may contain a draft notes file under `specs/022-9io-vote-report/findings.md` if helpful; it does NOT contain the docs page yet.

## Slice B — write the docs page

- [ ] T022-S2 — author `docs/case-studies/2026-io-budget-vote.md` with all sections from FR-1 through FR-7
- [ ] T022-S2 — externalise queries to `docs/case-studies/2026-io-budget-vote.queries/*.rq` if the page becomes too dense
- [ ] T022-S2 — register the page in `mkdocs.yml`
- [ ] T022-S2 — `mkdocs build` clean
- [ ] T022-S2 — every numeric claim in the page matches the slice A measurements
- [ ] T022-S2 — commit: `docs(case-study): 9-IO 2026 budget vote process — SPARQL-driven report` with `Tasks: T022-S2`

## Finalization

- [ ] T022-F — PR body audit
- [ ] T022-F — drop `gate.sh`
- [ ] T022-F — flip PR ready
- [ ] T022-F — post-merge cleanup
