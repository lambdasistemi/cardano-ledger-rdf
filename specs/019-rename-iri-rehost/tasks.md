# Tasks — Rename, transactions.ttl move, vocab IRI re-host

Issue: [#19](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/19)

## Slice A — internal rename sweep (no IRI change)

- [ ] T019-S1 — rename `cardano-rdf.cabal` → `cardano-ledger-rdf.cabal`; update `name:` field; align `cabal.project` if it pins the package name
- [ ] T019-S1 — sweep `flake.nix` package outputs and any `cardano-rdf` literal in `nix/checks.nix`
- [ ] T019-S1 — sweep `README.md`, `AGENTS.md`, `CLAUDE.md`, `CHANGELOG.md`, `mkdocs.yml` for repo-name references
- [ ] T019-S1 — sweep `.github/workflows/{release,deploy-docs}.yml`
- [ ] T019-S1 — sweep `specs/README.md`, `specs/001-extract-tx-rdf/{spec,plan}.md`, `.specify/memory/constitution.md`
- [ ] T019-S1 — sweep `docs/prior-art.md`, `docs/operations/secrets.md`
- [ ] T019-S1 — sweep source files for repo-name string literals (not vocab IRI): `Overlay.hs`, `Bech32.hs`, `VocabExport.hs`, `Turtle.hs`
- [ ] T019-S1 — verify `nix build .#checks.x86_64-linux.unit` and `cabal build all -O0` green
- [ ] T019-S1 — commit: `chore(rename): cardano-rdf → cardano-ledger-rdf (internal sweep, IRI unchanged)` with `Tasks: T019-S1`

## Slice B — import transactions.ttl + serve at /vocab/cardano

- [ ] T019-S2 — copy `data/rdf/transactions.ttl` from `/code/cardano-knowledge-maps/data/rdf/transactions.ttl` into `vocab/cardano/transactions.ttl` in this repo; add provenance comment at top
- [ ] T019-S2 — update `mkdocs.yml` to include the file in the docs site under the path that serves to `/vocab/cardano`
- [ ] T019-S2 — verify `mkdocs build` clean locally; verify `text/turtle` Content-Type plumbing if possible (best-effort — note in WIP.md if unclear)
- [ ] T019-S2 — verify `nix build .#checks.x86_64-linux.unit` green (no behaviour change expected)
- [ ] T019-S2 — commit: `feat(vocab): import transactions.ttl + serve at /vocab/cardano (IRI still old)` with `Tasks: T019-S2`

## Slice C — re-host vocab IRI

- [ ] T019-S3 — update `cardanoPrefix` constant in `src/Cardano/Tx/Graph/Emit/Vocab.hs` to `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#`
- [ ] T019-S3 — sweep remaining source IRI literals: `JsonLd.hs`, `Overlay.hs`, `NoStubViewSpec.hs`, `TurtleShim.hs`, `LoadImportsSpec.hs`, `LoadTurtleSpec.hs`
- [ ] T019-S3 — regenerate goldens via harness (or `sed` sweep if harness regen produces non-prefix-only diffs); verify the diff is prefix-only
- [ ] T019-S3 — update `docs/may-2026-amaru-lattice.md` if it cites the IRI inline
- [ ] T019-S3 — verify `nix build .#checks.x86_64-linux.*` green
- [ ] T019-S3 — smoke: run `tx-graph` on `test/fixtures/tx-graph/02-alice-bob-ada/cbor` and confirm the prefix in stdout/the file is the new IRI
- [ ] T019-S3 — commit: `feat(vocab): re-host vocab IRI to cardano-ledger-rdf` with `Tasks: T019-S3`

## Companion PR — cardano-knowledge-maps removal

- [ ] T019-C — file a tracking issue in `lambdasistemi/cardano-knowledge-maps` referencing #19
- [ ] T019-C — bootstrap worktree + branch + draft PR in `cardano-knowledge-maps`
- [ ] T019-C — `git rm data/rdf/transactions.ttl`; add `data/rdf/transactions.ttl.MOVED.md` with redirect note pointing at this repo's path
- [ ] T019-C — verify `cardano-knowledge-maps` tests pass (whatever its gate is) without the file
- [ ] T019-C — commit + push; PR stays draft until #19 PR merges

## Finalization

- [ ] T019-F — PR body audit: matches delivered behaviour (rename + import + IRI swap)
- [ ] T019-F — drop `gate.sh` in `chore: drop gate.sh (ready for review)` commit
- [ ] T019-F — `gh pr ready` on this repo's PR
- [ ] T019-F — once #19 PR merged: flip the cardano-knowledge-maps companion PR to ready
- [ ] T019-F — post-merge cleanup: `git worktree remove`, delete remote branches, prune
