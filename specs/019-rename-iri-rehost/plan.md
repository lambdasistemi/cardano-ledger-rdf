# Plan — Rename, transactions.ttl move, vocab IRI re-host

Issue: [#19](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/19)

## Tech stack

- Haskell `cardano-rdf` package (renaming to `cardano-ledger-rdf`); existing GHC 9.12.3 + cabal + flake.nix toolchain
- MkDocs for the docs site (already in repo at `mkdocs.yml`); deployed via `.github/workflows/deploy-docs.yml`
- Goldens harness (`just unit` / nix-checks suite) for fixture regeneration
- Companion repo `cardano-knowledge-maps` for the transactions.ttl removal (separate PR)

## Slice boundaries

Three slices, each one bisect-safe commit. Slice A is name-only (no behavior change in emitted Turtle). Slice B adds the vocab artefact in place (still no IRI change). Slice C swaps the IRI everywhere.

### Slice A — internal rename sweep (no IRI change)

**Touches name only, never the vocab IRI.** After this slice, the cabal package is `cardano-ledger-rdf`, all docs/READMEs/workflows match, and the build is green.

Files:
- `cardano-rdf.cabal` → `cardano-ledger-rdf.cabal` (file move + `name:` field)
- `cabal.project`, `flake.nix`, `nix/checks.nix`, `.github/workflows/release.yml`, `.github/workflows/deploy-docs.yml`
- `README.md`, `AGENTS.md`, `CLAUDE.md`, `CHANGELOG.md`, `mkdocs.yml`
- `specs/README.md`, `specs/001-extract-tx-rdf/{spec,plan}.md`, `.specify/memory/constitution.md`
- `docs/prior-art.md`, `docs/operations/secrets.md`
- Source files referring to the repo *name* (not the vocab IRI): `src/Cardano/Tx/Graph/Rules/Load/Emit/Overlay.hs`, `src/Cardano/Tx/Graph/Rules/Load/Bech32.hs`, `src/Cardano/Tx/Graph/Emit/VocabExport.hs`, `src/Cardano/Tx/View/Turtle.hs`

Owned: above list. Forbidden: any `cardano-knowledge-maps/vocab/cardano#` literal — that's slice C. Tests pass at HEAD.

### Slice B — import transactions.ttl + serve at /vocab/cardano

**Lands the artefact. No IRI swap yet.** After this slice, the file is present in this repo at the path that MkDocs serves to the new IRI URL, but emitted Turtle still uses the OLD IRI (slice C swaps).

Steps:
- Copy `data/rdf/transactions.ttl` from `cardano-knowledge-maps` into `vocab/cardano/transactions.ttl` here (preserve content verbatim; provenance comment added at top).
- Update `mkdocs.yml` to include the file in the site, served at `/vocab/cardano` (the file's bare name becomes a directory page; the .ttl file is served raw).
- Verify the local `mkdocs serve` build emits the file at the expected URL path with `text/turtle` Content-Type (configure MIME if necessary in CI's docs job).

Owned: `vocab/cardano/`, `mkdocs.yml`, possibly `docs/` for a one-line index entry. Forbidden: vocab IRI literals.

### Slice C — re-host vocab IRI

**The behaviour-changing swap.** Every place the literal `https://lambdasistemi.github.io/cardano-knowledge-maps/vocab/cardano#` exists becomes `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#`.

Source (6 files):
- `src/Cardano/Tx/Graph/Emit/Vocab.hs` (the canonical `cardanoPrefix` constant — single source of truth)
- `src/Cardano/Tx/View/JsonLd.hs`
- `src/Cardano/Tx/Graph/Rules/Load/Emit/Overlay.hs` (string literal)
- `test/Cardano/Tx/Graph/Emit/NoStubViewSpec.hs`
- `test/fixtures/tx-graph/Fixtures/TxGraph/TurtleShim.hs`
- `test/Cardano/Tx/Graph/Rules/{LoadImportsSpec,LoadTurtleSpec}.hs`

Fixtures (~38): every `test/fixtures/tx-graph/*/expected*.ttl` and `test/fixtures/canonical-vocab/{derived,transactions}.ttl`. Regenerate from the harness rather than `sed`-editing where possible.

Docs: `docs/may-2026-amaru-lattice.md`.

Owned: above list + regenerated fixtures. Forbidden: any rename or transactions.ttl artefact changes (those are slices A & B).

### Companion PR — cardano-knowledge-maps removal

Separate worktree at `/code/cardano-knowledge-maps-issue-XX` (where XX = the matching ticket I file there). Branch `XX-remove-transactions-ttl`. Single commit:
- `git rm data/rdf/transactions.ttl`
- Add a `data/rdf/transactions.ttl.MOVED.md` redirect note pointing at the new repo's path.

Stays in draft until this repo's #19 PR is merged.

## Gate

Per-slice: `nix build --quiet -L .#checks.x86_64-linux.unit && cabal build all -O0 && just unit`. Slice C additionally must show new IRI in a smoke fixture: `grep "cardano-ledger-rdf/vocab/cardano" test/fixtures/tx-graph/02-alice-bob-ada/expected.ttl`.

Finalization gate: `nix build .#checks.* -L` clean from main; `mkdocs build` clean; PR description audit.

## Risks

- **GH Pages MIME for `.ttl`**: MkDocs may serve `.ttl` as `text/plain` by default; CI or repo Settings may need to set `text/turtle`. Mitigation in slice B: verify with `curl -sI` against a preview deploy.
- **Old IRI consumers**: anyone who imported the old IRI for Turtle prefix declarations will break silently after slice C. Mitigation: note in epic + companion PR; no automatic redirect on GH Pages for arbitrary paths.
- **Fixture regen drift**: if the goldens harness regenerates anything beyond the prefix swap (e.g. canonical bnode ordering changed), the diff balloons. Mitigation: review the diff in slice C; if it's not just the prefix swap, scope back and investigate.
