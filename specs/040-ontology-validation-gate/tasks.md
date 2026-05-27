# Tasks — Port ontology validation gate

## Slice 1 — full port (T040-S1)

- [X] T040-S1 — Port `validate-graph-sources.py` → `scripts/validate-ttl.py` (drop JSON config; glob `vocab/**/*.ttl`)
- [X] T040-S1 — Port `owl-smoke.py` → `scripts/owl-smoke.py` (glob `vocab/**` for the union ontology; preserve fixture/ASK/EXPECT contract)
- [X] T040-S1 — Add `nix/eye.nix` (local EYE derivation)
- [X] T040-S1 — Extend `flake.nix` dev shell with `pythonEnv = python3.withPackages [rdflib]` and `eye`
- [X] T040-S1 — Expose `vocab-validate` and `vocab-owl-smoke` derivations under `checks.x86_64-linux` in `nix/checks.nix`
- [X] T040-S1 — Add `vocab-validate` and `vocab-owl-smoke` just recipes; include in `just ci`
- [X] T040-S1 — Extend `.github/workflows/ci.yml` Build Gate with the two new check derivations
- [X] T040-S1 — Copy `baseline.{n3,ask}` and `sameas-key.{n3,ask}` from upstream to `test/fixtures/vocab/smoke/`
- [X] T040-S1 — Extend `gate.sh` `Tasks:` regex with `T040-S1`
- [X] T040-S1 — Verify `nix develop -c just vocab-validate` exits 0 (510 triples)
- [X] T040-S1 — Verify `nix develop -c just vocab-owl-smoke` exits 0 (4 ASK matched across 2 fixtures)
- [X] T040-S1 — Verify `nix build .#checks.x86_64-linux.vocab-validate` succeeds
- [X] T040-S1 — Verify `nix build .#checks.x86_64-linux.vocab-owl-smoke` succeeds
- [X] T040-S1 — `./gate.sh origin/main..HEAD` exits 0
- [X] T040-S1 — Commit slice with subject `feat(vocab): port TTL + OWL 2 RL validation gate from cardano-knowledge-maps` and `Tasks: T040-S1` trailer
