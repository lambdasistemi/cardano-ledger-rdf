# Tasks — Typed `native_script` tree walker

## Slice — Recursive native-script tree (closes #13)

- [X] T013-S1 — read `.worker-brief.md` and `.specify/memory/constitution.md`
- [X] T013-S1 — create `specs/013-native-script-walker/spec.md`, `plan.md`, and `tasks.md`
- [X] T013-S1 — add focused RED tests for nested multisig, timelock leaves, and witness-side native scripts
- [X] T013-S1 — add shared `Cardano.Tx.Graph.Emit.NativeScript` walker with stable `_cN` child bnodes
- [X] T013-S1 — rewire output reference-script emission in `Project.hs`
- [X] T013-S1 — rewire witness script emission in `Witness.hs`
- [X] T013-S1 — declare vocab terms in `Vocab.hs`, public Turtle, canonical-vocab fixture, and derived fragment
- [X] T013-S1 — add two tx-graph fixtures for nested multisig and timelock native scripts
- [X] T013-S1 — regenerate affected goldens and document the cascade in `WIP.md`
- [X] T013-S1 — run `nix develop -c just unit`
- [X] T013-S1 — run `nix build .#checks.x86_64-linux.{build,unit,lint,vocab-validate,vocab-owl-smoke}`
- [X] T013-S1 — extend `gate.sh` task regex if needed and run `./gate.sh origin/main..HEAD`
- [X] T013-S1 — commit `feat(tx): typed native_script tree walker (multisig + timelocks)` with `Tasks: T013-S1`
