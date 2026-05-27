# Dataset selection

The lattice was assembled from the 9 IO `gov_action1` IDs published on
IO Momentum.

### Step 1 - start from IO's published gov_action IDs

The 9 IO proposal pages linked from `https://momentum.cardano.iog.io/governance`
publish CIP-129 governance action IDs. Those `gov_action1...` IDs are the
seed list.

```sh
# Example seed from the Consensus proposal page:
gov_action1w0shrfxqwv95kk0v4cn34wylz25a2cmqkq5jpc0e2yrahhqava3qqfu3vtv
```

### Step 2 - decode gov_action IDs to txid and index

CIP-129 bech32 governance action IDs encode the governance action
transaction id plus the action index. Decoding the 9 IO IDs shows one
shared submission transaction with indices 0 through 8.

```sh
# CIP-129: https://cips.cardano.org/cip/CIP-0129
# decoded result for all 9 IO IDs:
txid=73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762
indices=0,1,2,3,4,5,6,7,8
```

### Step 3 - confirm titles via Koios proposal_list

Koios `proposal_list` confirmed that the shared submission transaction
contains 9 proposal rows, indices 0 through 8. The titles are Developer
Experience, Cardano Upgrades, Consensus, Cardano Maintenance,
L2 Scalability, Cardano High Assurance, Plutus, Blockfrost, and Pogun.

```sh
curl -sS "https://api.koios.rest/api/v1/proposal_list?limit=200&order=block_time.desc" \
  | jq '[.[] | select(.proposal_tx_hash == "73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762")]
        | sort_by(.proposal_index)
        | map({ix: .proposal_index, title: (.meta_json.body.title // .meta_url)})'
```

### Step 4 - enumerate voting transactions via Koios vote_list

For each of the 9 `gov_action1...` IDs, `vote_list` returns the vote rows
that target that action. Across the 9 actions this produced 2,374 vote
rows and **1,687 unique vote transaction hashes**.

```sh
curl -sS -G "https://api.koios.rest/api/v1/vote_list" \
  --data-urlencode "proposal_id=eq.gov_action1w0shrfxqwv95kk0v4cn34wylz25a2cmqkq5jpc0e2yrahhqava3qqfu3vtv" \
  --data-urlencode "select=vote_tx_hash,voter_role,vote,block_time"
```

Some vote transactions contain votes for other governance actions in the
same body. The report queries below therefore filter back to the IO
submission txid before counting tallies.

### Step 5 - fetch CBOR via Koios tx_cbor

The final CBOR cache is the submission transaction plus the union of the
1,687 vote transaction hashes. CBOR was fetched in batches of 50 hashes
and saved as `<txid>.cbor`.

```sh
curl -sS -X POST https://api.koios.rest/api/v1/tx_cbor \
  -H "Content-Type: application/json" \
  -d '{"_tx_hashes":["73e171a4...","002df859...", "..."]}'
```

| source | count |
| --- | ---: |
| submission tx | 1 |
| unique vote txs (union across 9 actions) | 1,687 |
| **total in lattice** | **1,688** |
| full enumeration | [`selections.txt`](selections.txt) (1,688 lines) |

Return to the [presentation](case.md).
