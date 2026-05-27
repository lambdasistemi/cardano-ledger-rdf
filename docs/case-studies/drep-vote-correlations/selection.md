# Dataset selection

This lattice follows the same five-step assembly as the 9-IO case study,
but widens the seed set from one bundled treasury submission to 20
Conway-era governance actions with enough DRep participation for
cross-action comparison.

### Step 1 - choose candidate governance actions

Candidate actions came from Koios `proposal_list`, ordered by recent block
time. The selection kept actions with more than 100 DRep vote rows and
favoured action-type and epoch diversity:

```sh
curl -sS \
  "https://api.koios.rest/api/v1/proposal_list?limit=250&order=block_time.desc"
```

The final set has 20 actions: 12 `TreasuryWithdrawals`, 5 `InfoAction`, 1
`ParameterChange`, 1 `NewConstitution`, and 1 `NewCommittee`. Proposal
epochs represented are 576, 579, 580, 586, 588, 603, 605, 612, and 632.

| Type | Actions |
| --- | ---: |
| TreasuryWithdrawals | 12 |
| InfoAction | 5 |
| ParameterChange | 1 |
| NewConstitution | 1 |
| NewCommittee | 1 |
| **Total** | **20** |

### Step 2 - decode CIP-129 governance action IDs

The `gov_action1...` identifiers were treated as CIP-129 identifiers. Koios
also returns the decoded transaction hash and proposal index, which are the
fields used by tx-graph's typed `cardano:GovActionId` blocks.

| Action | Type | Tx index | DRep rows | Title |
| --- | --- | ---: | ---: | --- |
| `8f54d021...#0` | InfoAction | 0 | 304 | Cardano Critical Integrations Budget |
| `47a0e7a4...#0` | NewCommittee | 0 | 292 | Replace Interim Constitutional Committee |
| `73e171a4...#0` | TreasuryWithdrawals | 0 | 277 | IO: Developer Experience Initiative |
| `73e171a4...#1` | TreasuryWithdrawals | 1 | 262 | IO: Cardano Upgrades |
| `73e171a4...#2` | TreasuryWithdrawals | 2 | 261 | IO: Consensus Initiative |
| `73e171a4...#3` | TreasuryWithdrawals | 3 | 262 | IO & Ensurable Systems: Cardano Maintenance |
| `73e171a4...#4` | TreasuryWithdrawals | 4 | 257 | IO & Midgard Labs: L2 Scalability |
| `73e171a4...#5` | TreasuryWithdrawals | 5 | 256 | IO: Cardano High Assurance |
| `73e171a4...#6` | TreasuryWithdrawals | 6 | 254 | IO & VacuumLabs: Enhancing Plutus |
| `73e171a4...#8` | TreasuryWithdrawals | 8 | 243 | Pogun: Capital Without Compromise |
| `90cf5197...#0` | InfoAction | 0 | 260 | ADA 5M Loan for Cardano's Global Listing Expansion |
| `8ad3d454...#19` | TreasuryWithdrawals | 19 | 257 | Native Asset CDN for Cardano Developers |
| `d16dffba...#0` | InfoAction | 0 | 251 | 2025 Net Change Limit Extension |
| `e5643c33...#0` | InfoAction | 0 | 249 | Stablecoin DeFi Liquidity Budget |
| `207b226e...#0` | NewConstitution | 0 | 248 | CARDANO BLOCKCHAIN ECOSYSTEM CONSTITUTION v2.0 |
| `8ad3d454...#30` | TreasuryWithdrawals | 30 | 244 | Tokenized Real Estate |
| `8ad3d454...#29` | TreasuryWithdrawals | 29 | 242 | Cardano Ecosystem Pavilions |
| `c21b00f9...#0` | ParameterChange | 0 | 240 | Increase Transaction and Block Memory Units |
| `8845bfc3...#0` | InfoAction | 0 | 228 | Name Protocol Version 11 hard fork - van Rossem |
| `f8393f1f...#0` | TreasuryWithdrawals | 0 | 214 | Cardano Critical Integrations Budget withdrawal |

### Step 3 - confirm selected actions via proposal_list

Each selected action was confirmed against `proposal_list`, including its
`proposal_tx_hash`, `proposal_index`, `proposal_type`, title, and proposal
epoch.

```sh
curl -sS "https://api.koios.rest/api/v1/proposal_list?limit=250&order=block_time.desc" \
  | jq '.[] | select(.proposal_id == "gov_action13a2dqgwxum7d6kjfprcs57cf9733ek2dkt5qnuhqd4ll5ntcwu7sqluwkxd")
        | {proposal_id, proposal_tx_hash, proposal_index, proposal_type, block_time,
           title: (.meta_json.body.title // .meta_json.title // .meta_url)}'
```

### Step 4 - enumerate voting transactions via Koios vote_list

For each selected `proposal_id`, `vote_list` returned the voting
transactions, voter role, verdict, epoch, and Koios block time. The tx-graph
lattice only uses CBOR transaction bodies; the Koios `block_time` field is
kept as sidecar evidence for the arrival-time limitation in Q6.

```sh
curl -sS -G "https://api.koios.rest/api/v1/vote_list" \
  --data-urlencode "proposal_id=eq.gov_action13a2dqgwxum7d6kjfprcs57cf9733ek2dkt5qnuhqd4ll5ntcwu7sqluwkxd" \
  --data-urlencode "select=vote_tx_hash,voter_role,voter_id,proposal_id,proposal_tx_hash,proposal_index,proposal_type,epoch_no,block_time,vote,meta_url"
```

The selected set contains 6,231 total vote rows, including 5,101 DRep vote
rows. For DRep/action correlation queries, revote ambiguity is handled by
using only DRep/action pairs with exactly one vote row in the lattice. That
leaves 4,563 unambiguous DRep/action observations and excludes 538 revote
rows.

### Step 5 - fetch CBOR via Koios tx_cbor

The CBOR cache is the union of all selected action submission transactions
and all unique vote transaction hashes returned by Step 4. CBOR is fetched
in batches of 50 hashes and saved as `<txid>.cbor`; `pipeline.sh` performs
that batching and then invokes `tx-graph`.

```sh
curl -sS -X POST https://api.koios.rest/api/v1/tx_cbor \
  -H "Content-Type: application/json" \
  -d '{"_tx_hashes":["73e171a4...","002df859...", "..."]}'
```

| Source | Count |
| --- | ---: |
| selected governance actions | 20 |
| unique action submission transactions | 11 |
| unique vote transactions | 5,288 |
| **total in lattice** | **5,299** |
| full enumeration | [`selections.txt`](selections.txt) |

Return to the [presentation](case.md).
