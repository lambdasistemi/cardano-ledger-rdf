# Demo — one transaction in, a typed business story out

`cardano-ledger-rdf` turns a Conway transaction into an RDF graph you can
read, pipe, and query. This page walks three pipelines on **real mainnet
data** — first one transaction, then the whole May 2026 Amaru treasury batch —
and shows the difference an operator overlay makes: raw addresses become named
scopes, and a pile of transactions becomes one queryable lattice.

Every command below runs against the current build. Nothing is hand-edited.

## Setup

```bash
# from a clone of this repo
nix develop                       # tx-graph, tx-view, arq are now on PATH
cabal build exe:tx-graph exe:tx-view -O0
export PATH="$(dirname "$(cabal list-bin exe:tx-graph -O0)"):$PATH"
export PATH="$(dirname "$(cabal list-bin exe:tx-view -O0)"):$PATH"
```

`tx-graph` reads a Conway transaction either from a local CBOR file or from a
chain indexer. Pick whichever you have:

```bash
# A. fetch by txid from a public indexer (no local node needed)
tx-graph --provider koios <txid>                       # free, rate-limited
tx-graph --provider blockfrost --token "$BLOCKFROST_PROJECT_ID" <txid>

# B. read a CBOR you already have on disk
tx-graph path/to/signed-tx.cbor
```

The canonical demo transaction is the May 2026 Amaru **network_compliance**
disbursement:

```
c150d5c5c67658c8f2a3bc24e16a4852257d46a03224257ac990fcca6f6fde78
```

The shell snippets below use `$C150` for that txid (provider mode) or
`$C150/tx.cbor` for a local CBOR; set whichever matches your setup.

## Pipeline 1 — bare: the explorer baseline

```bash
tx-graph --provider koios "$C150" | tx-view --graph - --view cli-tree
```

```text
inputs:
  - txOutRef: 3c3d5332cb159a5f0b42cf48a6f897f1603f94fb4405c6f0c1146d5feb627963#1
  - txOutRef: 44454ed0def64621ef645958830f599b488b699b28e3797cc37c4f4dd1463a79#2
  - txOutRef: 77b1b046d1bfb1a09011d4606817ea45d13d8d9e0d02258984d0c6126e4cc9e9#1
referenceInputs:
  - txOutRef: 11ace24a7b0caad4a68a38ef2fff18185dc9ea604e84425dab487cae94e4cf54#0
  - txOutRef: 25ba96f5deb14bb5c56e7542d6a9ba8450f52cc698ebd74574e1a0525d861095#2
  - txOutRef: 810bfcbde85ae72f27d7e8cd154c03c802de15d3fa0dd83a32a4b0fdba330b3c#0
  - txOutRef: e7b395a93d49a17994d66df0e4778a01dee05e7711e6612f28d97b63e4e6311c#2
outputs:
  - address: addr1xyezq8wpaqnssdjvd3p220uf7e6nzjae44w6yu625y965rfjyqwur6p8pqmycmzz55lcnan4x99mnt2a5fe54ggt4gxs8thzgk
    coin: 3.422443 ADA
    assets:
      - <urn:cardano:id:AssetClass:c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad0014df105553444d>: 1664173527
  - address: addr1q8qrds2nnx7clx3kcpp2l0eu45twmdcahsfu9m0xcwy59j6xz3vs0hnfaz9nhje8z34kfnds4jyk7hs6dnrag6e2lfgqtyf4rl
    coin: 1.189560 ADA
    assets:
      - <urn:cardano:id:AssetClass:c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad0014df105553444d>: 18750000000
  - address: addr1qx9aqvsf6gne2640jec828s25gzhk5wp2day8u24kf8mrs2v0zyuvk80fay35dx008p45ts0u6cdrv9g2maetq8jm8psznjcrz
    coin: 89.406649 ADA
withdrawals:
  - account: <urn:cardano:id:StakeScript:a64d1b9e1aeffe54056034d84977061b45a92691efc282fbee3fc094>
    amount: 0.000000 ADA
collateral:
  - txOutRef: 44454ed0def64621ef645958830f599b488b699b28e3797cc37c4f4dd1463a79#2
fee: 0.516135 ADA
```

Opaque hex, raw bech32 addresses, an asset identified only by its policy and
name bytes. This is exactly what every block explorer already shows. Useful,
but it tells you *nothing* about what the transaction means to the treasury.

## Pipeline 2 — typed: the same tx, with the operator overlay

Add `--rules`, pointing at the operator-authored
[`rules.yaml`](case-studies/2026-05-amaru-treasury/case.md) — a small file that
declares the treasury's scopes, vendors, and assets, plus the blueprint
registry for the on-chain scripts.

```bash
tx-graph --provider koios \
  --rules docs/case-studies/2026-05-amaru-treasury/rules.yaml \
  "$C150" \
| tx-view --graph - --view cli-tree
```

```text
outputs:
  - address: amaru-treasury.network_compliance
    coin: 3.422443 ADA
    assets:
      - <urn:cardano:id:AssetClass:c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad0014df105553444d>: 1664173527
  - address: amaru.cag-payee
    coin: 1.189560 ADA
    assets:
      - <urn:cardano:id:AssetClass:c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad0014df105553444d>: 18750000000
  - address: amaru.network-wallet
    coin: 89.406649 ADA
```

Same bytes, same transaction — but the three outputs now read in the
operator's own vocabulary:

| bare (pipeline 1)        | typed (pipeline 2)                  | meaning                                           |
|--------------------------|-------------------------------------|---------------------------------------------------|
| `addr1xyezq8w…8thzgk`    | `amaru-treasury.network_compliance` | the treasury scope being disbursed from           |
| `addr1q8qrds2…tyf4rl`    | `amaru.cag-payee`                   | the vendor-payment bridge — receives 18,750 USDM  |
| `addr1qx9aqvsf…znjcrz`   | `amaru.network-wallet`              | change back to the network wallet                 |

That single substitution — `addr1q8qrds2…` → `amaru.cag-payee` — is the whole
point of the overlay: the disbursement of **18,750 USDM** to the vendor bridge
is now legible at a glance instead of being one anonymous address among
millions. The redeemers and datums are carried in the graph as raw CBOR
(`cardano:hasRawBytes`); where a script's blueprint is registered and its datum
matches the schema, `tx-graph` also decodes it into typed fields (see the
[blueprint fixtures](tx-graph.md)).

!!! note "Why `--graph -`"
    `tx-view` reads the canonical Turtle graph from `--graph FILE`, or from
    **stdin** with `--graph -`. The `-` is what lets `tx-graph … | tx-view`
    work as a pipe. Diagnostics (e.g. "parent tx not in lattice", expected when
    you emit a single tx without its parents) ride **stderr**, so the Turtle on
    stdout stays clean for the next stage.

## Pipeline 3 — compose the batch into one lattice

A single transaction is the entry point; the real story is how *N* of them
compose. Concatenating per-transaction Turtle **is** the merge — outputs and
inputs that refer to the same UTxO share a content-addressed IRI
([#56](https://github.com/lambdasistemi/cardano-ledger-rdf/pull/56),
[#57](https://github.com/lambdasistemi/cardano-ledger-rdf/pull/57)), so the
graphs join on contact.

```bash
cd docs/case-studies/2026-05-amaru-treasury

# overlay once (entities, vendors, attestations, blueprints)
tx-graph --rules rules.yaml > /tmp/may.ttl

# then one transaction body per line of the selection
while read -r txid; do
  case "$txid" in \#*|"") continue ;; esac
  tx-graph --provider koios "$txid"            # or: --provider blockfrost --token "$BLOCKFROST_PROJECT_ID"
done < selections.txt >> /tmp/may.ttl
```

If you already hold the signed CBORs locally, skip the indexer entirely:

```bash
for f in cbor/*.cbor; do tx-graph "$f"; done >> /tmp/may.ttl
```

!!! info "Dataset for the figures below"
    `selections.txt` lists the 101 transactions of the May 2026 batch (30
    disbursement seeds + 71 closure parents). The numbers on this page were
    produced from the **67 of those transactions** available in the operator's
    local CBOR archive at capture time; fetching the full selection through a
    provider reproduces the same per-transaction graphs and the complete
    figures reported in the
    [case study](case-studies/2026-05-amaru-treasury/case.md).

### Where did the USDM go?

```bash
arq --data /tmp/may.ttl --query docs/demo/queries/usdm-received-per-scope.rq
```

```text
-------------------------------------------------------------------
| scope                               | usdm_received   | outputs |
===================================================================
| "other (pool / batcher / external)" | 27449731.870652 | 69      |
| "amaru-treasury.network_compliance" | 1556199.505786  | 58      |
| "amaru.cag-payee"                   | 418750.0        | 2       |
-------------------------------------------------------------------
```

Across the batch, **418,750 USDM** reached the vendor-payment bridge
(`amaru.cag-payee`), **1.56M USDM** cycled through the network_compliance
scope, and **27.4M USDM** moved through SundaeSwap pools and batchers (the
`other` row) as the treasury swapped to and from the stablecoin. The query
ranges over every output in the lattice and groups by the scope each recipient
address resolves to — no per-transaction bookkeeping.

### Which transaction spent which? (cross-tx join)

```bash
arq --data /tmp/may.ttl --query docs/demo/queries/spends-graph.rq | head -12
```

```text
| prod           | ix | cons           | scope                               |
==============================================================================
| "013329ee0504" | 0  | "7e0d63c45ed7" | "amaru.swap-order"                  |
| "013329ee0504" | 1  | "0f9818a51aad" | "amaru.swap-order"                  |
| "013329ee0504" | 2  | "432eef5e39ad" | "amaru.swap-order"                  |
| "013329ee0504" | 3  | "7fa113e90232" | "amaru.swap-order"                  |
| "013329ee0504" | 4  | "d0dba5b8f18f" | "amaru.swap-order"                  |
| "013329ee0504" | 5  | "ad6ac0a18897" | "amaru-treasury.network_compliance" |
| "013329ee0504" | 6  | "ad6ac0a18897" | "other"                             |
| "019586ee09f5" | 0  | "71ff129b5e0b" | "amaru-treasury.network_compliance" |
| "019586ee09f5" | 1  | "71ff129b5e0b" | "other"                             |
| "021e6b48610d" | 0  | "affe90d1fa9a" | "amaru-treasury.network_compliance" |
| "021e6b48610d" | 1  | "affe90d1fa9a" | "other"                             |
| "02fce56796d2" | 1  | "65bfd93936ab" | "amaru-treasury.network_compliance" |
```

(txids truncated to first 12 hex chars for display; the query returns them in
full via `SUBSTR(?txhash, 1, 12)`.) Each row is one **realised spend edge**:
consumer transaction *B* spent output `#ix` of producer transaction *A*,
where *both* transactions are in the lattice. The first row in the result —
`013329ee0504` output 0 spent by `7e0d63c45ed7` — is the per-response join
working live: each side was emitted by an independent `tx-graph` invocation,
catted into one Turtle, joined through the shared `urn:cardano:utxo:` IRI by
SPARQL with no synthetic fixtures involved.

### Where did the biggest single USDM movements land?

```bash
arq --data /tmp/may.ttl --query docs/demo/queries/top-usdm-outputs.rq
```

```text
-------------------------------------------------------------------------
| tx_id          | scope                               | usdm           |
=========================================================================
| "245d6a8ed9e6" | "other (pool / batcher / external)" | 3331363.867442 |
| "8f60266b475f" | "other (pool / batcher / external)" | 493470.382567  |
| "26542f223ee2" | "other (pool / batcher / external)" | 491489.726018  |
| "4e2642080c8d" | "other (pool / batcher / external)" | 490819.149109  |
| "ee9d02118fce" | "other (pool / batcher / external)" | 490763.540646  |
| "e96ce306b486" | "other (pool / batcher / external)" | 490713.336606  |
| "375c82a8a316" | "other (pool / batcher / external)" | 490549.550744  |
| "432eef5e39ad" | "other (pool / batcher / external)" | 490145.268246  |
-------------------------------------------------------------------------
```

Every top-eight USDM movement in the batch landed in the **`other`** scope —
the SundaeSwap batcher and pool addresses the treasury swapped through. The
single biggest event was **3,331,363 USDM** in tx `245d6a8ed9e6`: a pool
recombination event captured on its way through the batch. The remaining
seven are all ~490K USDM each — the **same swap-order pattern repeated eight
times**, visible at a glance because the per-output query bypasses the
producer/consumer chain and just looks at recipient values. Cross-scope
movements into the treasury appear further down the result set; the top
band belongs entirely to the DEX intermediary.

### On-chain payment ↔ off-chain accountability

The overlay also carries the audit trail: which vendors are paid through the
bridge, and the IPFS-pinned invoices and contracts that back them. One query
joins it to everything above:

```bash
arq --data /tmp/may.ttl --query docs/demo/queries/vendor-attestations.rq
```

```text
| vendor             | role                  | invoice                | ipfs                       |
==========================================================================================================
| "amaru.antithesis" | "fuzz-testing vendor" | "Invoice INV-635"      | <ipfs://bafkreicnoadl…>    |
| "amaru.castellum"  | "engineering vendor"  | "Contract"             | <ipfs://bafybeib3jef3…>    |
| "amaru.castellum"  | "engineering vendor"  | "Invoice"              | <ipfs://bafybeigy37ui…>    |
| "amaru.castellum"  | "engineering vendor"  | "May2026 cycle review" | <ipfs://bafybeihdmnit…>    |
```

These attestations are written by the overlay in the W3C Turtle
blank-node-property-list form (`[] a cardano:Attestation ; …`) — the form that
now round-trips cleanly through `tx-view`.

## Watch it run

A 38-second `asciinema rec` capture of the three pipelines above, run live against the binaries from this PR — bare cli-tree, typed cli-tree with operator scopes, multi-tx lattice + SPARQL — no fabrication, the numbers in the prose match the cast frame-for-frame.

<div class="asciinema-demo">

```asciinema-player
{
  "file": "demo/cast.cast",
  "auto_play": false,
  "speed": 1.0,
  "theme": "asciinema",
  "rows": 32,
  "cols": 100
}
```

</div>

## Reproduce

```bash
nix develop
cabal build exe:tx-graph exe:tx-view -O0
export PATH="$(dirname "$(cabal list-bin exe:tx-graph -O0)"):$(dirname "$(cabal list-bin exe:tx-view -O0)"):$PATH"

C150=c150d5c5c67658c8f2a3bc24e16a4852257d46a03224257ac990fcca6f6fde78

# 1 — bare
tx-graph --provider koios "$C150" | tx-view --graph - --view cli-tree

# 2 — typed
tx-graph --provider koios \
  --rules docs/case-studies/2026-05-amaru-treasury/rules.yaml "$C150" \
| tx-view --graph - --view cli-tree

# 3 — lattice + SPARQL
cd docs/case-studies/2026-05-amaru-treasury
tx-graph --rules rules.yaml > /tmp/may.ttl
while read -r t; do case "$t" in \#*|"") continue ;; esac
  tx-graph --provider koios "$t"; done < selections.txt >> /tmp/may.ttl
arq --data /tmp/may.ttl --query ../../demo/queries/usdm-received-per-scope.rq
arq --data /tmp/may.ttl --query ../../demo/queries/spends-graph.rq
arq --data /tmp/may.ttl --query ../../demo/queries/vendor-attestations.rq
```

Swap `--provider koios` for `--provider blockfrost --token "$BLOCKFROST_PROJECT_ID"`,
or drop the provider flag and pass local CBOR paths — the graphs, and the
answers, are the same.
