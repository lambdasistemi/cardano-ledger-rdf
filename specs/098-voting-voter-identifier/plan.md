# Implementation Plan: resolvable voting-procedure voter identifiers

**Branch**: `feat/98-voting-voter-identifier` · **Spec**: [spec.md](spec.md)

## Technical Context

- Haskell/GHC 9.12.3; RDF body emission lives in
  `tx-rdf-core/src/Cardano/Tx/Graph/Emit/Project.hs`.
- `resolveCredentialAndIntroduceIdent` already creates the deterministic
  identifier IRI and its `Identifier`, `leafType`, and `bytesHex` triples.
- `VoteSpec` provides focused, synthetic `ConwayTx` voting-procedure coverage;
  the repository golden harness keeps registered fixture output byte-stable.

## Constitution Check

- **Stable vocabulary and reproducible graphs**: pass. The existing
  identifier vocabulary is reused and a byte-diff golden pins the new graph
  shape.
- **Generic core**: pass. This is generic Conway governance credential
  emission; no operator or treasury semantics are added.
- **Offline determinism**: pass. The test transaction and golden are local.
- **Spec-first, TDD, verified**: pass. One driver-owned RED-to-GREEN slice
  adds regression coverage, emitter wiring, and the golden proof.

## Mapping Contract

| Ledger voter form | Existing voter class | Identifier leaf type |
| --- | --- | --- |
| `CommitteeVoter (KeyHashObj ...)` | `VoterCommitteeCold` | `CommitteeHotKey` |
| `CommitteeVoter (ScriptHashObj ...)` | `VoterCommitteeCold` | `CommitteeHotScript` |
| `DRepVoter (KeyHashObj ...)` | `VoterDRep` | `DRepKey` |
| `DRepVoter (ScriptHashObj ...)` | `VoterDRep` | `DRepScript` |
| `StakePoolVoter ...` | `VoterStakePool` | `PoolId` |

## Slice S1 — Identifier emission and voting-procedure golden

1. Make the focused voter tests fail by expecting `hasIdentifier` to point at
   the proper deterministic identifier IRI and checking the identifier's type,
   leaf type, and bytes for each mapping row.
2. Change voter discrimination to retain the leaf type with the existing class
   term and credential bytes; route the voter object through
   `resolveCredentialAndIntroduceIdent` in `emitVoterBlock`.
3. Add and register one voting-procedure fixture in the existing golden
   harness, including its fixture builder, rules file, expected Turtle, and
   traceability registration. Regenerate only its expected Turtle; no existing
   golden may change.
4. Run the focused test, full unit suite, repository `gate.sh`, and the full
   `just ci` gate before committing one bisect-safe slice. Also run the
   issue-named Nix check set explicitly.

**Commit**: `feat: type voting-procedure voter identifiers`

## Expected Implementation Surface

- `tx-rdf-core/src/Cardano/Tx/Graph/Emit/Project.hs`
- `test/Cardano/Tx/Graph/Emit/VoteSpec.hs`
- `test/Cardano/Tx/Graph/EmitGoldenSpec.hs`
- `test/Cardano/Tx/Graph/Emit/VocabTraceabilitySpec.hs`
- `test/fixtures/tx-graph/Fixtures/TxGraph/S37_VotingProcedure.hs`
- `test/fixtures/tx-graph/37-voting-procedure/rules.yaml`
- `test/fixtures/tx-graph/37-voting-procedure/expected.ttl`
- `cardano-ledger-rdf.cabal` (only to register the fixture module)

## Verification

```sh
nix develop --quiet -c just unit match="VoteSpec"
EMIT_GOLDEN_REGEN=1 nix develop --quiet -c just unit
git diff --check
./gate.sh origin/main..HEAD
nix develop --quiet -c just ci
nix build .#checks.x86_64-linux.{build,unit,lint,vocab-validate,vocab-owl-smoke}
```

The regeneration diff must be restricted to the new fixture's expected Turtle;
any unrelated golden change is a blocker.
