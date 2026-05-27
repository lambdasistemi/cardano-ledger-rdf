# Case study #28 WIP

## 2026-05-27T15:57:16+01:00 - brief received

Loaded `.worker-brief.md`, the repository constitution, the GitHub issue body,
and the 9-IO case-study template.

## 2026-05-27T16:08:44+01:00 - actions selected

Selected 20 governance actions with more than 100 DRep vote rows each:
12 TreasuryWithdrawals, 5 InfoAction, 1 ParameterChange, 1 NewConstitution,
and 1 NewCommittee action. Proposal epochs represented: 576, 579, 580, 586,
588, 603, 605, 612, and 632.

Selected actions:

- `gov_action13a2dqgwxum7d6kjfprcs57cf9733ek2dkt5qnuhqd4ll5ntcwu7sqluwkxd`
  - Cardano Critical Integrations Budget
- `gov_action1g7sw0f8e8qa34lppj2erksvzf4j6e9udwaq6efslc8apdqeazygsq2spyyt`
  - Replace Interim Constitutional Committee
- `gov_action1w0shrfxqwv95kk0v4cn34wylz25a2cmqkq5jpc0e2yrahhqava3qqfu3vtv`
  - IO: Developer Experience Initiative
- `gov_action1w0shrfxqwv95kk0v4cn34wylz25a2cmqkq5jpc0e2yrahhqava3qx4njfhm`
  - IO & Ensurable Systems: Cardano Maintenance Initiative
- `gov_action1w0shrfxqwv95kk0v4cn34wylz25a2cmqkq5jpc0e2yrahhqava3qz6es0cp`
  - IO: Cardano Upgrades
- `gov_action1w0shrfxqwv95kk0v4cn34wylz25a2cmqkq5jpc0e2yrahhqava3qyxkn2yk`
  - IO: Consensus Initiative
- `gov_action1jr84r96lnsvu9yd6c0jhxe9gj5r7vnd2pgkntc6klplxdpyzz4tqqc9uldx`
  - Budget: ADA 5M Loan for Cardano's Global Listing Expansion
- `gov_action13tfag48nf94rtjcdq7c06vhkslmxxw9h6c88sl7q5g5nnewcsvlpx66gmxa`
  - A free Native Asset CDN for Cardano Developers
- `gov_action1w0shrfxqwv95kk0v4cn34wylz25a2cmqkq5jpc0e2yrahhqava3qghg4q43`
  - IO & Midgard Labs: L2 Scalability Initiative
- `gov_action1w0shrfxqwv95kk0v4cn34wylz25a2cmqkq5jpc0e2yrahhqava3q2yd5rxu`
  - IO: Cardano High Assurance Technical Collaboration
- `gov_action1w0shrfxqwv95kk0v4cn34wylz25a2cmqkq5jpc0e2yrahhqava3qvczhx6t`
  - IO & VacuumLabs: Enhancing Plutus
- `gov_action169kllwhfmp488je5x5rwvufd08p8sztdcf0ghf5sp6ey2gnjdwaqql47xry`
  - 2025 Net Change Limit Extension
- `gov_action1u4jrcvlkppjzuv5j9z5ksacwtvv77h6glu0knpcjut8gvjjfu0cqqt3alsy`
  - Stablecoin DeFi Liquidity Budget
- `gov_action1ypajyms3pcfmkx93r87dxy6jpc8u6pst90ylhxj7t0rwjj43puasq0x9jrw`
  - CARDANO BLOCKCHAIN ECOSYSTEM CONSTITUTION v2.0
- `gov_action13tfag48nf94rtjcdq7c06vhkslmxxw9h6c88sl7q5g5nnewcsvlpuz29v77`
  - High-yield RWA Asset for Cardano: Tokenized Real Estate
- `gov_action1w0shrfxqwv95kk0v4cn34wylz25a2cmqkq5jpc0e2yrahhqava3qsuae57l`
  - Pogun: Capital Without Compromise
- `gov_action13tfag48nf94rtjcdq7c06vhkslmxxw9h6c88sl7q5g5nnewcsvlp679xfzf`
  - Cardano Ecosystem Pavilions at Exhibitions
- `gov_action1cgdsp7g0rr7wgqp7maptpvx525fxuqwfgm5qe3f5r20ew5x2772sq0m5y83`
  - Increase Transaction and Block Memory Units (Part 1 of 2)
- `gov_action13pzmlsmmktmfareqpl3gzj9nm63ugwvmp3y7urkjhd8rf89tn6msq95mp3f`
  - Name Protocol Version 11 hard fork - van Rossem
- `gov_action1lqun78lcznfa2gek49m3ydslakfnm8heargfp8sax9fk54yl6ghsqp042zv`
  - Withdraw ADA 70,000,000 for Cardano Critical Integrations Budget

## 2026-05-27T16:09:31+01:00 - selections.txt assembled

Assembled `docs/case-studies/drep-vote-correlations/selections.txt` with
5,299 unique transaction hashes: 11 action submission transactions and 5,288
unique vote transactions.

## 2026-05-27T16:10:02+01:00 - rules.yaml entities declared

Declared 2 entity rules: `io.budget-guard-policy` for script hash
`fa24fb305126805cf2164c161d852a0e7330cf988f1fe558cf7d4a64`, and
`intersect.treasury-holding` for stake credential
`8583857e4a12ffe1e6f641a1785a0f2f036c565cfbe6ff9db8e5a469`.

## 2026-05-27T16:18:50+01:00 - pipeline.sh tested

Ran `docs/case-studies/drep-vote-correlations/pipeline.sh` with the built
`tx-graph` on `PATH`. It fetched 5,299 CBOR files and emitted
`/tmp/io-gov-actions/drep-correlations-pipeline/lattice.ttl`: 38 MB and
808,976 lines. `riot --validate` accepted the emitted Turtle.

## 2026-05-27T16:22:10+01:00 - q1 verified

Pairwise agreement over unambiguous DRep/action observations found 19,440
DRep pairs with at least 10 common selected actions. Top aligned pairs reach
100% agreement over 20 common actions; top divergent pairs reach 0% over up
to 14 common actions.

## 2026-05-27T16:22:10+01:00 - q2 verified

Using edges with at least 12 common actions and at least 90% agreement,
post-processing found 4 connected components with at least two DReps. The
largest component has 142 DReps and spans proposal epochs 576-632.

## 2026-05-27T16:22:10+01:00 - q3 verified

Among DReps with at least 5 unambiguous observations, 229 of 313 changed
verdict at least once. The 84 mono-verdict DReps break down into 82 Yes-only
and 2 No-only.

## 2026-05-27T16:22:10+01:00 - q4 verified

Same-verdict pair rates by action type: ParameterChange 93.2%,
NewCommittee 89.9%, InfoAction 79.6%, TreasuryWithdrawals 60.6%, and
NewConstitution 51.9%.

## 2026-05-27T16:22:10+01:00 - q5 verified

Among 313 DReps with at least 5 unambiguous observations, 109 anchored at
least half of their votes and 204 did not. High-anchor DReps averaged 13.5
high-agreement neighbours; lower-anchor DReps averaged 19.3.

## 2026-05-27T16:22:10+01:00 - q6 verified

The lattice does not expose block time, so early-vs-late dynamics are not a
SPARQL-native claim. Koios sidecar check: first-quartile DRep votes aligned
with eventual DRep majority 943/1,270 times; last-quartile votes aligned
1,026/1,270 times.

## 2026-05-27T16:22:10+01:00 - case.md drafted

Drafted the presentation and six query pages under
`docs/case-studies/drep-vote-correlations/`.

## 2026-05-27T16:23:44+01:00 - mkdocs build green

`nix develop --quiet -c mkdocs build` exited 0.

## 2026-05-27T16:25:12+01:00 - committed SHA 82e3324

Committed as `82e3324` with subject
`docs(case-study): DRep vote correlation across governance actions`.

## 2026-05-27T17:24:04+01:00 — brief received

Read `.worker-brief.md`, `.specify/memory/constitution.md`, and
`gh issue view 30 --repo lambdasistemi/cardano-ledger-rdf`.

Investigation findings before code changes:

- `LeafType` already has internal body-walker constructors `LtTxId` and
  `LtGovActionId`, rendered as `cardano:leafType "TxId"` and
  `"GovActionId"` by the graph emitter.
- YAML `parseLeafType` only accepts the older operator-facing labels, so
  `keys: [TxId]` and `keys: [GovActionId]` fail today.
- `parseCompoundKey` validates all `bytes:` payloads as 28-byte hex, so it
  also rejects 32-byte transaction hashes and cannot accept the
  `<txid_hex>:<index>` GovActionId authoring shape.
- Emitted transaction IDs already flow through `LtTxId`; emitted voting
  action IDs currently use `LtGovActionId` for the action transaction hash
  only, so the rules lookup needs a text-keyed path for the selected
  `txid:index` identity shape.

## 2026-05-27T17:25:43+01:00 — RED TxId parser coverage

Added focused parser and vote-emitter regression tests. Ran
`nix develop --quiet -c just unit "TxId compound-key"` and observed the
expected failure: `keys: unknown leafType label: TxId`.

## 2026-05-27T17:30:06+01:00 — leaf-type extension applied

Extended YAML and Turtle leaf-type parsing to accept `TxId` and
`GovActionId`, mapping them to the existing `LtTxId` and
`LtGovActionId` constructors. Added byte-keyed lookup support for `TxId`
and text-keyed lookup support for `GovActionId`, then updated vote emission
so a matching `txid:index` rule uses the operator entity bnode.

## 2026-05-27T17:30:06+01:00 — GovActionId bytes parsing decision

Implemented the brief's option (a): `bytes: <txid_hex>:<index>`.
`TxId` validates as 32-byte hex. `GovActionId` validates the 32-byte tx id
and a decimal action index, stores the canonical text token, and maps that
token onto `_:hash_govactionid_<txid>_<index>` when no operator entity owns
the identity.

## 2026-05-27T17:32:37+01:00 — fixture/golden added

Added `test/fixtures/tx-graph/18-rules-txid-govactionid/` with
`rules.yaml` and `expected.entities.ttl` covering `keys: [TxId]` and
`keys: [GovActionId]`. Registered it in the rules-loader golden spec and
verified it with `nix develop --quiet -c just unit "18-rules-txid-govactionid"`.

## 2026-05-27T17:32:37+01:00 — docs/rules-yaml.md updated

Updated `docs/rules-yaml.md` to list `TxId` and `GovActionId` among
supported `keys:` labels and to document the `GovActionId`
`<txid_hex>:<index>` bytes format.

## 2026-05-27T17:38:43+01:00 — gate green

Verification passed:

- `nix develop --quiet -c just unit` — 522 examples, 0 failures.
- `./gate.sh origin/main..HEAD` — exit 0.
- `nix build --quiet -L .#checks.x86_64-linux.{build,unit,lint}` —
  exit 0 after staging the new fixture files so Nix included them in the
  source snapshot.
