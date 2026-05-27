# Plan — Port ontology validation gate

## Tech stack

- **rdflib** (Python) — TTL parser; SPARQL ASK evaluator over the OWL closure.
- **EYE** — reasoning engine for OWL 2 RL. Packaged locally as `nix/eye.nix`.
- **Nix flake** — wires `pythonEnv = python3.withPackages [rdflib]` and `eye` into both the dev shell and the two `checks.x86_64-linux.*` derivations.
- **just** — operator-facing recipes (`vocab-validate`, `vocab-owl-smoke`, plus inclusion in `just ci`).
- **GitHub Actions** — the existing `Build Gate` job adds the two new flake checks; no new workflow file.

## Slice boundaries

One slice. The harness has no value half-implemented (a recipe without
its CI counterpart, or a CI check without local recipe parity, leaves
the gate inconsistent between operator and bot). The unit of bisect
safety is "the gate runs end-to-end".

### Slice 1 — full port

Files:

- `scripts/validate-ttl.py` — port of upstream `validate-graph-sources.py`. Drops the `data/config.json` indirection; globs `vocab/**/*.ttl`.
- `scripts/owl-smoke.py` — port of upstream `owl-smoke.py`. Rebased to glob `vocab/**` for the union ontology; same fixture / ASK / EXPECT contract.
- `nix/eye.nix` — local EYE derivation (same pattern as upstream).
- `flake.nix` — add `pythonEnv` and `eye` to the default dev shell.
- `nix/checks.nix` — expose `vocab-validate` and `vocab-owl-smoke` under `checks.x86_64-linux`.
- `justfile` — `vocab-validate` and `vocab-owl-smoke` recipes; include in `just ci`.
- `.github/workflows/ci.yml` — extend `Build Gate` with `.#checks.x86_64-linux.vocab-validate` and `.#checks.x86_64-linux.vocab-owl-smoke`.
- `test/fixtures/vocab/smoke/baseline.n3`, `baseline.ask` — copied verbatim from upstream.
- `test/fixtures/vocab/smoke/sameas-key.n3`, `sameas-key.ask` — copied verbatim from upstream.
- `gate.sh` — extend `Tasks:` regex with `T040-S1`.

Gate:

- `nix develop -c just vocab-validate` exits 0.
- `nix develop -c just vocab-owl-smoke` exits 0 (4 ASK, all match EXPECT).
- `nix build .#checks.x86_64-linux.vocab-validate` succeeds.
- `nix build .#checks.x86_64-linux.vocab-owl-smoke` succeeds.
- `./gate.sh origin/main..HEAD` exits 0.

## Risks

- **EYE in nix store**: `eye` is not a stock nixpkgs derivation here today; we package it ourselves (`nix/eye.nix`). Risk: pkgs version drift breaks the build. Mitigation: pin the EYE source revision in the derivation as upstream does.
- **rdflib SPARQL semantics**: `EXPECT: true|false` checks rely on rdflib's ASK behavior over the EYE-produced closure. Upstream proved this works for these two fixtures; risk is contained to the fixtures present today. Future fixtures may need extra rule fragments loaded.
- **Flake-evaluator visibility of new files**: Nix flakes ignore untracked files. Drivers must `git add` new files before running `nix build`. Documented in the worker brief.
- **CI runner closure size**: First green build pulls EYE + Python + rdflib closures (~several hundred MB). Subsequent runs hit Cachix. Mitigation: none required; one-time cost.

## Why one slice and not two

A separate "validate only" slice followed by a "smoke" slice was
considered. Rejected: both share the same dev-shell wiring (rdflib +
EYE), the same nix-check shape, and the same CI workflow edit. A
validate-only slice would land 80% of the infrastructure with 50% of
the value, then a follow-up slice would amend that infrastructure
again — net more churn for the same surface.
