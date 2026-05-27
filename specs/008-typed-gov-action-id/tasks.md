# Tasks — Typed `gov_action_id` sub-node on votes

## Slice — typed `GovActionId` sub-block (closes #8)

- [X] T008-S1 — verify (`grep -n "formatGovActionId" src/`) the call site that currently emits the string literal; identify the surrounding vote-emit function
- [X] T008-S1 — add `TermGovActionId` to `src/Cardano/Tx/Graph/Emit/Vocab.hs` if absent; confirm `TermHasTxId` + `TermHasIndex` already declared
- [X] T008-S1 — replace the literal emit with a typed sub-block emit: `_:govActionIdK` of class `cardano:GovActionId` carrying `cardano:hasTxId _:hash_govactionid_<full-hex>` + `cardano:hasIndex <int>`
- [X] T008-S1 — introduce identifier leaf-role `govactionid` if the bnode-naming machinery uses a fixed enum; otherwise reuse generic hash naming
- [X] T008-S1 — declare `cardano:GovActionId` in `vocab/cardano/transactions.ttl`; widen `cardano:hasVotingAction` range from string to the new class
- [X] T008-S1 — judgment call on FR-3: drop the legacy string-literal `hasVotingActionId` predicate (no consumer in goldens) OR retain it; document in commit message
- [X] T008-S1 — regenerate goldens via the harness's regen mode; verify diffs are purely substitutive
- [X] T008-S1 — smoke: SPARQL `SELECT (COUNT(DISTINCT ?txid) AS ?n) WHERE { ?v cardano:hasVotingAction/cardano:hasTxId ?txid }` against a multi-vote-same-action fixture returns 1 (rather than N)
- [X] T008-S1 — verify `nix build .#checks.x86_64-linux.unit` green
- [X] T008-S1 — commit: `feat(emitter): typed gov_action_id sub-block on votes (mirror TxOutRef pattern)` with `Tasks: T008-S1`

## Finalization

- [X] T008-F — PR body audit
- [X] T008-F — drop `gate.sh` in `chore: drop gate.sh (ready for review)`
- [ ] T008-F — `gh pr ready` (REST API — orchestrator)
- [ ] T008-F — post-merge cleanup: worktree + branch
