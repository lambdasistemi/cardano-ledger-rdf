# Tasks — tx-graph lattice-mode `--out FILE`

## Slice — implement `--in-dir + --out FILE`

- [ ] T026-S1 — relax the CLI exclusivity check in `app/tx-graph/Main.hs` so `--in-dir DIR + --out FILE` is a valid combo
- [ ] T026-S1 — add a typed lattice-merge emitter in `Cardano.Tx.Graph.Emit.Serialize.Turtle` (or wherever the existing single-tx Turtle serializer lives) that takes the lattice and produces one Turtle doc with the documented header + per-tx section comments + bnode-renaming policy
- [ ] T026-S1 — wire the new emitter into the CLI's `--in-dir + --out` branch
- [ ] T026-S1 — add a 2-tx fixture under `test/fixtures/tx-graph/<NN>-lattice-merged/` with `expected.lattice.ttl` golden
- [ ] T026-S1 — verify the bnode-renaming is implemented at the type-level (not via string regex)
- [ ] T026-S1 — document the mode in `docs/tx-graph.md` (one paragraph + an example)
- [ ] T026-S1 — `nix build .#checks.x86_64-linux.unit` green
- [ ] T026-S1 — smoke: run on `/tmp/io-gov-actions/cbor/` (1,688 tx), confirm ARQ returns total = 162,145,961 ADA across 9 Proposal subjects
- [ ] T026-S1 — commit: `feat(emitter): tx-graph lattice-mode --in-dir + --out FILE (single merged Turtle)` with `Tasks: T026-S1`

## Finalization

- [ ] T026-F — PR body audit
- [ ] T026-F — drop `gate.sh`
- [ ] T026-F — `gh pr ready` (orchestrator)
- [ ] T026-F — post-merge cleanup
