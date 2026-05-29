# Tasks — #61 demo for real (T061-S1)

Single bisect-safe slice. One commit.

(Issue #61's bug 1 "warnings → stdout" was withdrawn — a live Blockfrost emit
confirmed diagnostics already ride stderr. No work needed; the slice covers
bugs 2 + 3, the cli-tree typed contrast, and the demo.)

- [x] T03 — FR-2: extend `Cardano.Tx.View.Turtle` for `[]` / `[ … ]`.
- [x] T04 — FR-2 pure spec via `renderView` (`TurtleSpec`).
- [x] T05 — FR-3: `tx-view --graph -` stdin + helpful missing-graph error.
- [x] T06 — FR-3 exe spec (`TxViewStdinSpec`), incl. `[]` over the pipe.
- [x] T07 — FR-4: `CliTree` entity resolution over IRI identifiers.
- [x] T08 — FR-4 pure spec (`CliTreeEntitySpec`); regenerate goldens 03/04.
- [x] T09 — Wire new modules into `unit-main.hs` + `.cabal`; full unit green.
- [x] T10 — Verify rules.yaml blueprint wiring intact; no case-study regress.
- [x] T11 — Build the May lattice; author + run `usdm-received-per-scope.rq`
      and `spends-graph.rq` with `arq`; capture real output.
- [ ] T12 — Write `docs/demo.md` (3 pipelines, real output, both providers).
- [ ] T13 — Record `docs/demo/cast.cast`; embed via `asciinema-player`.
- [ ] T14 — Link from `docs/index.md`; add `mkdocs.yml` nav entry; build
      under `mkdocs --strict`.
- [ ] T15 — Extend `gate.sh` `Tasks:` regex with `T061-S1`; update
      `CHANGELOG.md`; commit.
