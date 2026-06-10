# Implementation Plan: depend on cardano-tx-tools:tx-build, delete the local builder copy

**Branch**: `refactor/86-tx-build-dependency` · **Spec**: ./spec.md
**Blocked by**: lambdasistemi/cardano-tx-tools#127 (S3 needs the reconciled SHA)

## Technical Context

- Haskell, GHC 9.12.3, haskell.nix `cabalProject'` (reads
  `source-repository-package` + `--sha256:` nix32 comments natively).
- `cardano-tx-tools:tx-build` (public sub-library, visibility: public)
  exposes exactly: `Cardano.Tx.{Balance,Build,Credentials,Deposits,Inputs,Ledger,Scripts,Witnesses}`.
  It does NOT contain `Evaluate`, `Decode`, or `Blueprint`.
- Import survey (current main):
  - The 8 builder modules are imported only by each other, the fixture
    generators (`test/fixtures/tx-graph/`), and the two builder specs.
  - `Cardano.Tx.Ledger` (a single type synonym `ConwayTx`) is also
    imported by kept library modules (`Graph.Emit`, `Graph.Emit.Project`,
    `Graph.Emit.Witness`, `Graph.Resolve.Web2`, `Decode`),
    `app/tx-graph/Main.hs`, and most test specs.
  - `Cardano.Tx.Evaluate` is imported by nothing.

## Key Design Decisions

1. **Atomic swap (S3).** Two visible packages exposing the same module
   name make every `import Cardano.Tx.Build` ambiguous. Therefore adding
   `tx-build` to the test-suite build-depends and deleting the local
   builder modules MUST land in one commit. There is no smaller
   bisect-safe step.
2. **Inline `ConwayTx` into `Cardano.Tx.Decode` (S2, unblocked).**
   `ConwayTx` is a type synonym — interchangeable across packages by
   construction. Moving it to the kept input-boundary module and
   retargeting ALL in-repo importers (library, app, tests, fixtures)
   lets `src/Cardano/Tx/Ledger.hs` be deleted before the pin exists,
   shrinking the blocked slice. Tests that need the tx type import it
   from `Cardano.Tx.Decode`; after S3 the name `Cardano.Tx.Ledger`
   resolves only to tx-build's copy (no in-repo module of that name
   remains).
3. **Solver scope for the pin.** `source-repository-package` brings the
   whole cardano-tx-tools package description into the solve. Its main
   library / node tools may need packages unavailable in
   CHaP+Hackage (their own cabal.project pins are not consulted), so the
   pin is accompanied by `package cardano-tx-tools` /
   `flags: -build-node-tools`, making the non-tx-build components
   non-buildable and excluding their deps from the solve. Verify at S3
   against the actual pinned cabal file; drop the flag stanza if the
   solve works without it.
4. **Goldens are the equivalence proof.** The fixtures rebuild the same
   transactions through tx-build's reconciled builder; every golden
   Turtle/JSON-LD file must stay byte-identical. Any golden diff means
   the #127 reconciliation missed behavior — stop and escalate, do not
   regold.

## Slices

### S1 — README integration-policy paragraph (docs, unblocked)

Add a short "Relationship to cardano-tx-tools" statement to README.md:
single source of truth for the builder is cardano-tx-tools:tx-build
(test-suite-only dependency here); cardano-tx-tools consumes cq-rdf at
the CLI boundary (pipes over `cq-rdf body` output), never by linking
this library — keeps the cross-repo graph acyclic by construction.
Commit: `docs: record the CLI-boundary integration policy with cardano-tx-tools`.

### S2 — inline ConwayTx, delete Cardano.Tx.Ledger (refactor, unblocked)

- Define + export `ConwayTx` in `Cardano.Tx.Decode` (with the same
  haddock note about synonym interchangeability).
- Retarget every `import Cardano.Tx.Ledger (ConwayTx)` to
  `import Cardano.Tx.Decode (ConwayTx)` across src/, app/, and test/.
  This includes the builder modules and specs that S3 later deletes
  (`Build`, `Balance`, `Scripts`, `Evaluate`, `BuildSpec`) — S2 must
  compile on its own, and the retarget there is mechanical churn on
  files that are already condemned.
- Delete `src/Cardano/Tx/Ledger.hs`; drop its exposed-modules entry.
- Full gate; goldens byte-identical (type-synonym move only).
Commit: `refactor: inline ConwayTx into Cardano.Tx.Decode, drop Cardano.Tx.Ledger`.

### S3 — pin tx-build, atomic swap + deletion (refactor, BLOCKED on #127)

- Ask the parent orchestrator for the reconciled cardano-tx-tools SHA
  (Q-file); compute `--sha256:` via
  `nix flake prefetch github:lambdasistemi/cardano-tx-tools/<sha>` +
  `nix hash convert --to nix32`.
- `cabal.project`: add `source-repository-package` (+ sha256 comment)
  and, if needed (decision 3), `flags: -build-node-tools`.
- Test-suite `build-depends`: add `cardano-tx-tools:tx-build`.
- Delete `src/Cardano/Tx/{Build,Balance,Evaluate,Witnesses,Deposits,Scripts,Credentials,Inputs}.hs`,
  `test/Cardano/Tx/BuildSpec.hs`, `test/Cardano/Tx/Build/MinUtxoSpec.hs`;
  remove their cabal entries (library exposed/other-modules; test-suite
  other-modules). Fixture imports stay as-is — they now resolve to
  tx-build.
- Adapt fixture call sites ONLY if the reconciled tx-build API requires
  it (expected: none; #127 exists to make the copies equivalent).
- Full gate; goldens byte-identical.
Commit: `refactor: swap the local builder copy for cardano-tx-tools:tx-build`.

### Finalization

PR body audit, `gh pr ready`. The repo-committed `gate.sh` stays (repo
convention: task-id allowlist registered per ticket, not the
add/drop-per-PR variant).

## Gate

```
./gate.sh                          # commit-message gate (repo-committed)
nix develop --quiet -c just ci     # build + unit (incl. goldens) + smokes
```

Golden byte-identity check (S2, S3): the unit suite's golden specs fail
on any diff; additionally `git diff origin/main -- test/data/ vocab/`
must stay empty for golden directories.

## Risks

- The reconciled tx-build API may not be drop-in for the fixtures → keep
  adaptation in S3, minimal; if goldens change, STOP (escalate, never
  regold).
- cabal solver may drag node-tools deps into the solve → decision 3.
- index-state: cardano-tx-tools comes via git so its own release cadence
  does not matter, but its dep bounds must be satisfiable at our pinned
  index-states; tx-build's bounds match ours (verified against its
  cabal file on main).
