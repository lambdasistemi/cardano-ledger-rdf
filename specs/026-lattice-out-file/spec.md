# Spec — tx-graph lattice-mode `--out FILE` (closes #26)

Closes [#26](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/26).

## Why

Producing a SPARQL-queryable lattice from N tx CBORs currently requires a Python preprocessor (see [PR #25](https://github.com/lambdasistemi/cardano-ledger-rdf/pull/25)'s `findings.md` and the slice-A driver's local debrief). The preprocessor exists only because ARQ's `--data` argv limit can't ingest 1,688 separate Turtle files, and `tx-graph` doesn't emit a single merged file. The fix is to let `tx-graph` emit the merged form directly with the same bnode-renaming policy the worker proved correct.

## P1 user story

As an operator producing a SPARQL-driven case study over a lattice of N transactions, I want `tx-graph --in-dir cbor/ --out lattice.ttl` to emit a single canonical Turtle file with:
- per-tx-position bnodes safely prefixed (so they're unique across files)
- content-addressed identifier bnodes (`_:hash_*`, `_:cred_*`) left untouched (so cross-tx joins work)

…so I can run `arq --data lattice.ttl --query Q.rq` directly without writing any scripting layer.

## Functional requirements

- **FR-1 — `--in-dir + --out FILE` mode.** When both flags are set, `tx-graph` emits ONE Turtle file containing every tx in the input dir.
- **FR-2 — Bnode-renaming policy.** Per-tx-position bnodes (those NOT matching `_:hash_*` or `_:cred_*`) are prefixed with the tx's id (or its 8-hex short form, consistent with the worker's verified approach). Identifier bnodes are unchanged so cross-tx dedup works.
- **FR-3 — Prefix block once.** The output begins with a single `@prefix` block; per-tx sections do NOT repeat prefixes.
- **FR-4 — Per-tx header comment.** Each tx's section is preceded by a `# === tx <full-id> ===` comment for human readability (matches the verified worker output).
- **FR-5 — Byte-stable.** Re-running on the same input dir produces a byte-identical output.
- **FR-6 — Existing modes untouched.** `--in-dir + --out-dir` (N→N), single-tx (`--tx + --out`), and rules-only (`--rules`) modes are unchanged.
- **FR-7 — Goldens cover the new path.** A small fixture of ≥ 2 tx CBORs gets a `expected.lattice.ttl` golden file; the unit suite enforces byte-equality.
- **FR-8 — SPARQL acceptance.** On the 9-IO fixture data (CBOR cache at `/tmp/io-gov-actions/cbor/`), the merged file produces the same answers as `findings.md` documents: 162,145,961 ADA across 9 proposals, 2,374 IO votes, single beneficiary, single guard policy.

## Out of scope

- The other workflow papercuts named in #26 (query helpers, runner script, `just` recipe, vocab/doc on credential bytes). Each is its own follow-up.
