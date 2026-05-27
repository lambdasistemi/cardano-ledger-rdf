# Tasks — Typed `ProposalProcedure` cluster

## Slice A — proposal shell (closes #4)

- [ ] T004-S1 — add `TermHasDeposit`, `TermHasReturnAddress` to `src/Cardano/Tx/Graph/Emit/Vocab.hs` (the existing `TermHasAnchor` is reused)
- [ ] T004-S1 — refactor `buildProposalCluster` in `src/Cardano/Tx/Graph/Emit/Project.hs` to emit `hasDeposit`, `hasReturnAddress`, `hasAnchor` on the proposal subject for every gov-action variant
- [ ] T004-S1 — emit a typed `cardano:Anchor` sub-block for the proposal's anchor field, reusing the vote-anchor shape (`anchorUrl`, `anchorHash`)
- [ ] T004-S1 — declare new predicates in `vocab/cardano/transactions.ttl` (labels, descriptions, domain/range where unambiguous); widen `cardano:hasAnchor` domain if needed
- [ ] T004-S1 — regenerate goldens via the harness's regen mode; verify diffs are additive (new predicates only)
- [ ] T004-S1 — verify `nix build .#checks.x86_64-linux.unit` green
- [ ] T004-S1 — commit: `feat(emitter): typed proposal_procedure shell (deposit + return_address + anchor)` with `Tasks: T004-S1`

## Slice B — `TreasuryWithdrawals` body (closes #3)

- [ ] T004-S2 — add `TermTreasuryWithdrawals`, `TermWithdrawal`, `TermHasGovAction`, `TermHasWithdrawal`, `TermToRewardAccount`, `TermHasLovelace`, `TermHasGuardPolicy` to `Vocab.hs`
- [ ] T004-S2 — case-split `buildProposalCluster` on the `GovAction` constructor; for `TreasuryWithdrawals`, emit a typed `_:govActionK` sub-block with `hasWithdrawal` per map entry + optional `hasGuardPolicy`; other constructors continue to use the existing fallback
- [ ] T004-S2 — each withdrawal sub-block emits `toRewardAccount` (reusing credential-bnode scheme) + `hasLovelace` (integer literal)
- [ ] T004-S2 — declare new classes + predicates in `vocab/cardano/transactions.ttl`
- [ ] T004-S2 — regenerate goldens; verify only TreasuryWithdrawals-bearing fixtures changed
- [ ] T004-S2 — verify `nix build .#checks.x86_64-linux.unit` green
- [ ] T004-S2 — smoke: SPARQL `SELECT (SUM(?ada) AS ?total) WHERE { ?p a cardano:Proposal ; cardano:hasGovAction/cardano:hasWithdrawal/cardano:hasLovelace ?ada }` against a TreasuryWithdrawals fixture returns the expected total
- [ ] T004-S2 — commit: `feat(emitter): typed TreasuryWithdrawals body (recipient + lovelace + guard policy)` with `Tasks: T004-S2`

## Finalization

- [ ] T004-F — PR body audit
- [ ] T004-F — drop `gate.sh` in `chore: drop gate.sh (ready for review)`
- [ ] T004-F — `gh pr ready` (orchestrator uses REST API per #21 lesson)
- [ ] T004-F — post-merge cleanup: worktree + branch
