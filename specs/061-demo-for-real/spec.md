# Spec — Demo the pipeline end-to-end, for real (#61)

## Problem

The story we tell operators is "one transaction in, one rendered view out,
by pipe":

```bash
tx-graph --provider koios <txid> | tx-view --view cli-tree
```

Today that fails on contact, and even when it renders, the typed view is
indistinguishable from the bare one — so the operator-overlay value
proposition (named scopes instead of raw addresses) is invisible. Several
defects block a believable demo, and there is no operator-facing page that
walks the three pipelines on real mainnet data.

(Issue #61's original "warnings → stdout" defect was withdrawn after a live
Blockfrost emit confirmed `tx-graph` already writes diagnostics to stderr; the
earlier reproduction had a `2>&1` operator error. This spec covers the real
remaining work.)

## Functional requirements

- **FR-2 (`[]` reader).** `tx-view`'s in-repo Turtle reader must accept the
  W3C Turtle §2.6 blank-node-property-list forms `[] predicateObjectList .`
  and `[ predicateObjectList ] .` — the form the overlay emitter uses for
  off-chain `cardano:Attestation` blocks — without hand-rewriting.
- **FR-3 (stdin).** `tx-view --graph -` reads the canonical Turtle graph
  from stdin, so the pipe works without a temp file. `--graph FILE` keeps
  working; omitting `--graph` is a usage error (exit 2) with a message that
  points at stdin.
- **FR-4 (typed contrast).** With `--rules` loaded, `tx-view --view cli-tree`
  must resolve output addresses to operator entity labels
  (`amaru-treasury.network_compliance`) and assets to their entity labels,
  rather than raw `addr1…` / `urn:cardano:id:AssetClass:…`. The resolution
  must work with the content-addressed `<urn:cardano:id:…>` identifier IRIs
  that the overlay emits since #57 (not only legacy blank nodes).
- **FR-5 (demo doc).** `docs/demo.md` walks an operator through three
  pipelines on the real mainnet tx `c150d5c5…` and the May 2026 Amaru batch:
  (1) bare, (2) typed with `--rules`, (3) multi-tx lattice + cross-tx SPARQL.
  Every command is copy-pasteable and runs against current `main`. The page
  builds under `mkdocs --strict` and is linked from `docs/index.md` + nav.
- **FR-6 (multi-tx + cross-tx SPARQL).** The demo composes N transactions
  into one lattice by concatenating per-tx Turtle, and answers at least one
  cross-tx question that joins consumer B's input to producer A's output via
  the #56/#57 IRI scheme, on real mainnet data.

## Non-goals

- Decoding redeemers into typed records in the cli-tree view. The real
  `c150d5c5…` redeemers carry raw CBOR that the bundled blueprint does not
  decode; the demo does not invent typed-redeemer rows. Typed datum decoding
  remains exercised by the existing blueprint fixtures.
- A `cardano:hasLatticeRole` seed/closure tag. tx-graph does not emit it;
  the demo queries range over all outputs/inputs directly.
- Modifying `rules.yaml` asset encodings or the 28-query case-study baseline.

## Acceptance

- `tx-graph emit | tx-view --graph - --view cli-tree` renders the
  network_compliance disbursement with no hand-rewriting.
- The typed pipeline's outputs show named scopes where the bare pipeline
  shows raw addresses.
- `docs/demo.md` builds under `mkdocs --strict`; pipelines 1–3 run on
  current `main`; the cross-tx query returns rows on real mainnet data.
- `nix develop -c just unit` green; `./gate.sh origin/main..HEAD` exits 0.
- Existing case-study query results are unchanged (no regression).
