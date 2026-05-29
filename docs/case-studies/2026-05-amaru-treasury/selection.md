# Dataset selection

The May 2026 Amaru Treasury lattice was assembled from the operator's
named May batch plus a one-hop transaction-input closure.

## Step 1 - start from the 30 named seed transactions

The seed set is the May 2026 operating batch used by the original SPARQL
presentation:

| source | count |
| --- | ---: |
| disbursements | 3 |
| reorganize transactions | 5 |
| swap-order transactions | 20 |
| swap cancel | 1 |
| scoop dive | 1 |
| **total seeds** | **30** |

Seed txids are included in [`selections.txt`](selections.txt). They are
also preserved in the local Amaru Treasury transaction archive under
`transactions/2026/` in the source operator repository.

## Step 2 - fetch closure parents from transaction CBOR

For each seed transaction, the closure walk fetches parent transaction
CBOR for every consumed input at depth 1. The shipped
[`pipeline.sh`](pipeline.sh) invokes `tx-graph --provider koios` to do
the CBOR pull; the only Koios endpoint used is the transaction-CBOR
fetch (no address, UTxO, input, or output convenience APIs).

The reproduced selection list was cross-checked from two sources:
Koios `tx_utxos` for normal consumed-input parents, and the local
operator archive's `inputs/<parent-txid>.cbor` files for reference and
collateral parents that are not returned by that Koios endpoint.

## Step 3 - write one txid per CBOR

The final lattice contains 101 transaction CBORs:

| source | count |
| --- | ---: |
| seeds | 30 |
| normal consumed-input parents | 63 |
| reference/collateral parents from local CBOR archive | 8 |
| **total in lattice** | **101** |

The full enumeration is [`selections.txt`](selections.txt), one txid per
line. Return to the [presentation](case.md).
