# Plan — Typed `ProposalProcedure` cluster

## Tech stack

- Haskell `cardano-ledger-rdf` library (the renamed package after #21 landed)
- `src/Cardano/Tx/Graph/Emit/Project.hs` — `buildProposalCluster` is the existing call site (~line 2719); `emitProposalDatumFallback` is the current per-variant fallback at line ~2750
- `src/Cardano/Tx/Graph/Emit/Vocab.hs` — `Term*` enum; add new terms here
- `vocab/cardano/transactions.ttl` — vocabulary file (now owned in this repo after #21)
- Goldens harness — re-generates fixtures via `EMIT_GOLDEN_REGEN=1` (the same mechanism slice C of #21 used)

## Slice boundaries

Two bisect-safe slices.

### Slice A — proposal shell (closes #4)

**Shape**: every `cardano:Proposal` gains `hasDeposit`, `hasReturnAddress`, `hasAnchor` predicates uniformly across all 7 gov-action variants. The per-variant body remains a `hasRawBytes` blob — slice B replaces it for `TreasuryWithdrawals`.

Files touched:
- `src/Cardano/Tx/Graph/Emit/Project.hs` — refactor `buildProposalCluster` to emit shell predicates on the `_:proposalK` subject before delegating to the per-variant payload emitter.
- `src/Cardano/Tx/Graph/Emit/Vocab.hs` — add `TermHasDeposit`, `TermHasReturnAddress` (`hasAnchor` already exists for vote anchors — reuse).
- `vocab/cardano/transactions.ttl` — declare the new predicates with labels, descriptions, and a widened domain on `hasAnchor` to cover `cardano:Proposal` in addition to `cardano:Vote`.
- Goldens regenerated.

### Slice B — `TreasuryWithdrawals` body (closes #3)

**Shape**: for `TreasuryWithdrawals` proposals, emit `cardano:hasGovAction _:govActionK` linking to a typed sub-block, which itself carries `cardano:hasWithdrawal` per map entry plus `cardano:hasGuardPolicy` (when set). The withdrawal sub-block reuses the credential-bnode scheme for the recipient stake address.

Files touched:
- `src/Cardano/Tx/Graph/Emit/Project.hs` — add a typed `emitTreasuryWithdrawalsBody` walker; case-split on `GovAction` constructor in `buildProposalCluster`; the other 6 constructors still fall through to the existing fallback.
- `src/Cardano/Tx/Graph/Emit/Vocab.hs` — `TermTreasuryWithdrawals` (class), `TermWithdrawal` (class), `TermHasGovAction`, `TermHasWithdrawal`, `TermToRewardAccount`, `TermHasLovelace`, `TermHasGuardPolicy`.
- `vocab/cardano/transactions.ttl` — declare class + predicates.
- Goldens regenerated (only the fixtures whose tx body contains a `TreasuryWithdrawals` proposal will change; the others see no diff).

## Gate

Per slice:
```
./gate.sh origin/main..HEAD                       # commit shape
nix build --quiet -L .#checks.x86_64-linux.unit  # goldens + behaviour
```

Slice B additionally must satisfy a smoke check against a real mainnet fixture: if the goldens harness includes a `TreasuryWithdrawals`-bearing fixture (e.g., `10-governance-treasury-withdrawal`), `tx-graph` on its CBOR must emit the typed `cardano:hasWithdrawal` triples.

## Risks

- **Anchor domain widening**: if `cardano:hasAnchor` currently has an explicit `rdfs:domain cardano:Vote` axiom in the vocab, widening it to a union `cardano:Vote ⊔ cardano:Proposal` is a semantic change. Mitigation: check the current declaration; if absent, FR-3 just adds the right domain. If present, the slice-A vocab change documents the widening.
- **Fixture regen scope creep**: `emit` is byte-stable per kmaps-vocab-derived expected.ttl files. Adding new predicates on the proposal subject changes the byte output of every fixture that has a proposal in its body. Mitigation: regen via `EMIT_GOLDEN_REGEN=1`; verify the diff is **additive only** for new predicates (no existing predicate's bytes change unrelated to the added lines).
- **Coexistence semantics**: the `_:proposalDatumK cardano:hasRawBytes "<hex>"` retained alongside the typed predicates means a SPARQL DESCRIBE on the proposal returns both — consumers must understand the typed predicates are authoritative when present. Mitigation: vocab annotation makes the relationship explicit (`rdfs:comment` on the new predicates noting the parallel raw view).
