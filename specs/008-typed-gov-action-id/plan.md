# Plan — Typed `gov_action_id` sub-node on votes

## Tech stack

- Haskell `cardano-ledger-rdf` library
- `src/Cardano/Tx/Graph/Emit/Project.hs` — the vote emitter is around line 2820–2860; the `OStringLit (formatGovActionId actionId)` call is the line being replaced
- `src/Cardano/Tx/Graph/Emit/Vocab.hs` — `Term*` enum
- `vocab/cardano/transactions.ttl` — vocab additions
- Goldens harness via `EMIT_GOLDEN_REGEN=1`

## Slice boundaries

One bisect-safe slice. The change is mechanically contained: replace one literal-emit with a typed sub-block emit, plus add vocab terms.

### Slice — replace string literal with typed `GovActionId` sub-block

Files touched:
- `src/Cardano/Tx/Graph/Emit/Project.hs` — modify the vote-emit code path (`buildVoteBlocks` or equivalent) to:
  1. Create a `_:hash_govactionid_<full-hex>` bnode for the TxId identifier leaf (reusing the existing leaf-name family — add a new `LeafType` role if necessary)
  2. Create a `_:govActionIdK` bnode of class `cardano:GovActionId` carrying `cardano:hasTxId` (linked to the identifier bnode) + `cardano:hasIndex` (integer literal)
  3. Replace `cardano:hasVotingAction "<txid>#<ix>"` with `cardano:hasVotingAction _:govActionIdK`
- `src/Cardano/Tx/Graph/Emit/Vocab.hs` — add `TermGovActionId` (class) if absent. `TermHasTxId` + `TermHasIndex` already exist (used by `TxOutRef`); confirm and reuse.
- `vocab/cardano/transactions.ttl` — declare `cardano:GovActionId` as `rdfs:Class`; update `cardano:hasVotingAction` range; add leafType role if introduced.
- Goldens regenerated for every vote-bearing fixture.

## Gate

```
./gate.sh origin/main..HEAD                          # commit shape
nix build --quiet -L .#checks.x86_64-linux.unit     # goldens + behaviour
```

Smoke: pick a fixture with 2+ votes on the same action (the goldens harness should have one, or use `07-vote-delegation` if it carries multiple votes on a single action). Run a SPARQL `SELECT ?action WHERE { ?v cardano:hasVotingAction/cardano:hasTxId ?action }` and confirm the votes collapse onto a single TxId identifier label.

## Risks

- **Bnode-naming collision**: the new `_:hash_govactionid_…` family must not collide with any existing identifier role. Likely `govactionid` is a fresh role; verify by grepping `Vocab.hs` and the goldens for the current `hash_*` patterns before introducing it.
- **Fixture regen drift**: every vote-bearing fixture changes. Verify the diff is **purely substitutive** (the old string literal triple goes away; the new sub-block triples appear) without disturbing anything else.
- **Identifier leaf-role plumbing**: if the existing emitter has a fixed list of identifier leafTypes (the family-role-fullhex naming scheme), adding `govactionid` may require touching the leafType enum + the rendered vocab in `transactions.ttl`. Plan accordingly.
- **Legacy literal predicate (FR-3 judgment call)**: keeping both the typed sub-block and a `hasVotingActionId` string literal doubles the triples per vote. If the goldens harness shows no consumer relies on the literal, drop it; commit message names the choice.
