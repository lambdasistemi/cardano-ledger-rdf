# Demo — one transaction in, a typed business story out

`cardano-ledger-rdf` turns a Conway transaction into an RDF graph you can
read, pipe, and query. This page walks three pipelines on **real mainnet
data** — first one transaction, then the whole May 2026 Amaru treasury
history — and shows the difference an operator overlay makes: raw
addresses become named scopes, an opaque asset becomes USDM, and a pile of
independent transactions becomes one queryable lattice.

Every command runs against the published build. Nothing is hand-edited,
and every number on this page is reproduced by a query you can see and
re-run. Any token below — transaction id, address, asset — links to
[CardanoScan](https://cardanoscan.io) so you can verify on a neutral third
party that the chain really says what we say it does.

## Setup

You need two executables — `cq-rdf` (the RDF runtime: overlay, body,
blueprint, shacl) and `tx-view` (RDF → human views) — plus `arq` (the
SPARQL CLI from Apache Jena) for the query section. Pick the install
path that fits you; they all produce identical graphs.

=== "Prebuilt binary (recommended)"

    Most operators and auditors don't want to compile Haskell. Grab a
    release artifact — no toolchain, no build:

    ```bash
    # Linux x86_64 — AppImage (also .deb / .rpm on the releases page)
    base=https://github.com/lambdasistemi/cardano-ledger-rdf/releases/latest/download
    curl -L "$base/cq-rdf-x86_64-linux.AppImage" -o cq-rdf && chmod +x cq-rdf
    curl -L "$base/tx-view-x86_64-linux.AppImage" -o tx-view && chmod +x tx-view
    # macOS arm64 — tarball: cq-rdf-aarch64-darwin.tar.gz (and tx-view-…)
    ```

    Browse [the latest release](https://github.com/lambdasistemi/cardano-ledger-rdf/releases/latest)
    for the exact asset names and your architecture. The same release
    still ships a deprecated `tx-graph` compatibility symlink for one
    cycle so existing scripts keep working; new work should target
    `cq-rdf` directly.

=== "Build from source (Nix)"

    Run straight from the flake — no clone, no `nix develop`:

    ```bash
    flake=github:lambdasistemi/cardano-ledger-rdf
    nix run $flake#cq-rdf  -- --help
    nix run $flake#tx-view -- --help
    ```

    To put them on `PATH` for a session:

    ```bash
    nix build github:lambdasistemi/cardano-ledger-rdf#cq-rdf github:lambdasistemi/cardano-ledger-rdf#tx-view -o result-bins
    export PATH="$PWD/result-bins/bin:$PATH"
    ```

`arq` comes from Apache Jena (`nix run nixpkgs#apache-jena -- ...`, or your
distro's `jena` package).

### Where the transaction comes from

`cq-rdf body` reads one Conway transaction either from a local CBOR
file or from a chain indexer — **the graph and every answer below are
identical whichever you pick**:

```bash
# A. fetch by txid from a public indexer (no local node)
cq-rdf body --provider koios <txid>                                  # free, rate-limited
cq-rdf body --provider blockfrost --token "$BLOCKFROST_PROJECT_ID" <txid>

# B. read a CBOR you already have on disk
cq-rdf body path/to/signed-tx.cbor
```

Provider, token, or local file — the emitter is pure, so swapping the
source can't change the result. The examples use a `$BLOCKFROST_PROJECT_ID`
already exported in the environment.

## Pipeline 1 — bare: the explorer baseline

The lead transaction is deliberately a **SundaeSwap swap**, not a plain
payment: a swap engages a contract, so it carries redeemers and an inline
order datum. That is exactly the material the overlay has to work on, and
exactly what a block explorer leaves as opaque bytes.

Our swap is
[`10a5c1da…`](https://cardanoscan.io/transaction/10a5c1dafe7dd8d4ab680e35dc53b8b550da90bea55f2c758f36474064f2e598)
— one rung of the treasury's ADA → USDM swap chain. Bare:

```bash
cq-rdf body --provider blockfrost --token "$BLOCKFROST_PROJECT_ID" \
  10a5c1dafe7dd8d4ab680e35dc53b8b550da90bea55f2c758f36474064f2e598 \
| tx-view --graph - --view cli-tree
```

<div class="scrollbox" markdown>

```text
inputs:
  - txOutRef: dfd355530e2d3baef6fc4cb22369c8b64aa117b0a84ff2cdaadc24cdc3fbc7bc#2
  - txOutRef: dfd355530e2d3baef6fc4cb22369c8b64aa117b0a84ff2cdaadc24cdc3fbc7bc#3
referenceInputs:
  - txOutRef: 11ace24a7b0caad4a68a38ef2fff18185dc9ea604e84425dab487cae94e4cf54#0
  - txOutRef: 25ba96f5deb14bb5c56e7542d6a9ba8450f52cc698ebd74574e1a0525d861095#2
  - txOutRef: 810bfcbde85ae72f27d7e8cd154c03c802de15d3fa0dd83a32a4b0fdba330b3c#0
  - txOutRef: e7b395a93d49a17994d66df0e4778a01dee05e7711e6612f28d97b63e4e6311c#2
outputs:
  - address: addr1x8ax5k9mutg07p2ngscu3chsauktmstq92z9de938j8nqaejyqwur6p8pqmycmzz55lcnan4x99mnt2a5fe54ggt4gxst7gy3n
    coin: 42.891805 ADA
    datum:
      hash: 7c413435da13eabb7117a425f3a495f84ddfc2f8eb9caf8f00d512995bfaf299
      rawBytes: d8799fd8799f581c64f35d26b237ad58e099041bc14c687ea7fdc58969d7d5b66e2540efffd87a9f9fd8799f581c7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffbffd8799f581cf3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2effd8799f581c8bd03209d227956aaf9670751e0aa2057b51c1537a43f155b24fb1c1ffd8799f581c97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2ffffff1a00138800d8799fd8799fd87a9f581c32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0dffd8799fd8799fd87a9f581c32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0dffffffffd87980ffd87a9f9f40401a025c6d9dff9f581cc48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad480014df105553444d1a00989681ffffd87980ff
  - address: addr1x8ax5k9mutg07p2ngscu3chsauktmstq92z9de938j8nqaejyqwur6p8pqmycmzz55lcnan4x99mnt2a5fe54ggt4gxst7gy3n
    coin: 42.891804 ADA
    datum:
      hash: 0ef54f5a163374af92cd46099e7a092857ed5d16ff48f1a0db91b476feae827d
      rawBytes: d8799fd8799f581c64f35d26b237ad58e099041bc14c687ea7fdc58969d7d5b66e2540efffd87a9f9fd8799f581c7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffbffd8799f581cf3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2effd8799f581c8bd03209d227956aaf9670751e0aa2057b51c1537a43f155b24fb1c1ffd8799f581c97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2ffffff1a00138800d8799fd8799fd87a9f581c32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0dffd8799fd8799fd87a9f581c32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0dffffffffd87980ffd87a9f9f40401a025c6d9cff9f581cc48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad480014df105553444d1a00989680ffffd87980ff
  - address: addr1xyezq8wpaqnssdjvd3p220uf7e6nzjae44w6yu625y965rfjyqwur6p8pqmycmzz55lcnan4x99mnt2a5fe54ggt4gxs8thzgk
    coin: 1449833.102132 ADA
  - address: addr1qx9aqvsf6gne2640jec828s25gzhk5wp2day8u24kf8mrs2v0zyuvk80fay35dx008p45ts0u6cdrv9g2maetq8jm8psznjcrz
    coin: 99.092459 ADA
withdrawals:
  - account: <urn:cardano:id:StakeScript:a64d1b9e1aeffe54056034d84977061b45a92691efc282fbee3fc094>
    amount: 0.000000 ADA
collateral:
  - txOutRef: dfd355530e2d3baef6fc4cb22369c8b64aa117b0a84ff2cdaadc24cdc3fbc7bc#3
fee: 0.454317 ADA
```

</div>

Raw bech32 addresses, two outputs locked at a script with an inline datum
that is just a wall of CBOR. This is what every explorer shows. It is
faithful, but it tells you *nothing* about what the transaction means to
the treasury: which scope is spending, what contract those datums belong
to, what's being bought.

## Pipeline 2 — typed: the same tx, with the operator overlay

The overlay is a small, operator-authored
[`overlay.yaml`](case-studies/2026-05-amaru-treasury/case.md): a flat
declaration of the treasury's scopes, the asset it trades, the vendors it
pays, and the on-chain contracts it engages. `cq-rdf overlay` emits it
as Turtle that concatenates with the body graphs. The file we end at is
the one the Amaru operator actually uses; rather than drop it on you
whole, we add it **one feature at a time** and watch each line earn its
keep.

### Rung 1 — name the scopes

```yaml
entities:
  - name: amaru-treasury.network_compliance
    from-address: addr1xyezq8wpaqnssdjvd3p220uf7e6nzjae44w6yu625y965rfjyqwur6p8pqmycmzz55lcnan4x99mnt2a5fe54ggt4gxs8thzgk
  - name: amaru.network-wallet
    from-address: addr1qx9aqvsf6gne2640jec828s25gzhk5wp2day8u24kf8mrs2v0zyuvk80fay35dx008p45ts0u6cdrv9g2maetq8jm8psznjcrz
  - name: amaru.swap.v2                       # the SundaeSwap order script, by hash
    script: fa6a58bbe2d0ff05534431c8e2f0ef2cbdc1602a8456e4b13c8f3077
```

Concatenate the overlay (`cq-rdf overlay --in overlay.yaml`) onto the
body, and the addresses in the **same** transaction resolve to the
operator's own names:

<div class="scrollbox" markdown>

```text
outputs:
  - address: amaru.swap.v2
    coin: 42.891805 ADA
    datum:
      hash: 7c413435da13eabb7117a425f3a495f84ddfc2f8eb9caf8f00d512995bfaf299
      rawBytes: d8799fd8799f581c64f35d26b237ad58e099041bc14c687ea7fdc58969d7d5b66e2540ef…
  - address: amaru.swap.v2
    coin: 42.891804 ADA
    datum:
      hash: 0ef54f5a163374af92cd46099e7a092857ed5d16ff48f1a0db91b476feae827d
      rawBytes: d8799fd8799f581c64f35d26b237ad58e099041bc14c687ea7fdc58969d7d5b66e2540ef…
  - address: amaru-treasury.network_compliance
    coin: 1449833.102132 ADA
  - address: amaru.network-wallet
    coin: 99.092459 ADA
```

</div>

The two opaque script outputs are now plainly the treasury *placing two
swap orders* at `amaru.swap.v2`; the 1.45M ADA is *change back to its own
operating scope*; the 99 ADA is the *network wallet*. One transaction, now
legible. (Entities can be matched by full address, like the scopes, or by
script hash, like `amaru.swap.v2` — which is why all of the protocol's
order UTxOs collapse to that one name.)

### Rung 2 — resolve the asset

The swap is buying USDM, but USDM on-chain is just a policy id plus a
hex-encoded name. Declare it once:

```yaml
  - name: usdm
    asset:
      policy: c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad
      name: USDM
```

Now a query can ask for `usdm` and report human units instead of matching
[`c48cbb…0014df10·USDM`](https://cardanoscan.io/token/c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad0014df105553444d)
and dividing raw quantities by a million by hand. We lean on this in every
money query below — it is what turns `18750000000` into **18,750 USDM**.

### Rung 3 — map the vendor bridge and its paperwork

Vendor payments leave the treasury through one bridge address,
`amaru.cag-payee`. Name it, declare who is paid through it, and attach the
off-chain attestations (IPFS-pinned invoices and contracts) that back each
one:

```yaml
  - name: amaru.cag-payee
    from-address: addr1q8qrds2nnx7clx3kcpp2l0eu45twmdcahsfu9m0xcwy59j6xz3vs0hnfaz9nhje8z34kfnds4jyk7hs6dnrag6e2lfgqtyf4rl
  - name: amaru.antithesis
    label: Antithesis Operations LLC
    role: fuzz-testing vendor
    paid-via: amaru.cag-payee
  - name: amaru.castellum
    label: Castellum Labs
    role: engineering vendor
    paid-via: amaru.cag-payee

attestations:
  - ipfs: ipfs://bafkreicnoadlgnc6cqxggxboho7yt532lkonxcusj3ndsxdnv5szyswyam
    label: Invoice INV-635
    of: amaru.antithesis
  # … contract, invoice, cycle-review for amaru.castellum
```

This is what makes the on-chain payment ↔ off-chain accountability join
(below) answerable: the bridge, the vendors behind it, and the documents
behind them are now all in the graph.

### Rung 4 — register the contract blueprint

Finally, register the contract's CIP-57 blueprint. The script at
`fa6a58bb…` is SundaeSwap V3's order validator, so we register its real
upstream blueprint:

```yaml
blueprints:
  - script: amaru.swap.v2
    datum: …/blueprints/sundaeswap-v3/plutus.json
```

This puts the contract's schema in the graph: the raw script hash is now
known to be the named SundaeSwap V3 order contract, and its on-chain data
is carried losslessly as `cardano:hasRawBytes` for anyone to inspect or
decode. Where a registered schema matches a datum, the
[`cq-rdf blueprint`](cq-rdf.md#blueprint) typed-decode pass emits the
fields as typed triples (e.g. `:SwapOrder_recipient …`) — exercised on a
matching shape by the [blueprint fixtures](cq-rdf.md).

!!! note "Honest limit on the live order datum"
    SundaeSwap's own blueprint types the order datum as opaque `Data`, and
    its surrounding CIP-57 definitions are recursive — which the current
    decoder does not resolve. So the live six-field V3 order above is
    **named and carried verbatim as raw CBOR, not decoded into fields**.
    This is a known gap, tracked alongside the case study (see its
    [limitations](case-studies/2026-05-amaru-treasury/case.md), gap #5),
    not a claim this page makes. Typed decode lands today on contracts
    whose schema is concrete; the recursive V3 datum is future work.

The complete file — every rung stacked together — is what we use for the
batch:

<div class="scrollbox" markdown>

```yaml
--8<-- "docs/case-studies/2026-05-amaru-treasury/overlay.yaml"
```

</div>

!!! note "Why `--graph -`"
    `tx-view` reads the canonical Turtle graph from `--graph FILE`, or from
    **stdin** with `--graph -` — that `-` is what lets `cq-rdf body … | tx-view`
    work as a pipe. Diagnostics (e.g. "parent tx not in lattice", expected
    when you emit one tx without its parents) ride **stderr**, so the Turtle
    on stdout stays clean for the next stage.

## Pipeline 3 — compose transactions into one lattice

### What's behind a TX-in?

Look back at the bare swap. Its first input is
`dfd355530e2d…#2`. That reference is the whole story of composition:
**behind every TX-in there is a transaction that created it as a TX-out.**
So ask the obvious question — *what produced `dfd355530e2d…#2`?* — and emit
that transaction too:

```bash
cq-rdf body --provider blockfrost --token "$BLOCKFROST_PROJECT_ID" \
  dfd355530e2d3baef6fc4cb22369c8b64aa117b0a84ff2cdaadc24cdc3fbc7bc > parent.ttl
cq-rdf body --provider blockfrost --token "$BLOCKFROST_PROJECT_ID" \
  10a5c1dafe7dd8d4ab680e35dc53b8b550da90bea55f2c758f36474064f2e598 > child.ttl
cat parent.ttl child.ttl > pair.ttl
```

Concatenating the two Turtle files **is** the merge. The parent's output
and the child's input both refer to the same UTxO, and they were emitted
as the same content-addressed `urn:cardano:utxo:` IRI
([#56](https://github.com/lambdasistemi/cardano-ledger-rdf/pull/56),
[#57](https://github.com/lambdasistemi/cardano-ledger-rdf/pull/57)), so the
two graphs join on contact — no database, no foreign keys. Two
transactions are now one graph, linked by the UTxO one spent from the
other.

### From a pair to a history — by address

You found that parent by following a txid. But an auditor rarely has the
txid; they have the **wallet**: *show me everything this treasury did.* A
public indexer answers that directly — "which transactions touched this
address?" — so instead of chasing txids one hop at a time, enumerate every
transaction in or out of each treasury scope and emit them all. That set,
de-duplicated, is [`docs/demo/selections.txt`](https://github.com/lambdasistemi/cardano-ledger-rdf/blob/main/docs/demo/selections.txt)
— 88 transactions:

| operating scope enumerated | transactions |
| --- | ---: |
| `amaru-treasury.network_compliance` | 85 |
| `amaru-treasury.contingency` | 2 |
| `amaru.swap-order` | 76 |
| `amaru.network-wallet` | 35 |
| **union, de-duplicated** | **88** |

(The vendor bridge `amaru.cag-payee` is a long-lived address shared across
many months, so it is *not* enumerated on its own — that would pull in
other cycles. Its two May payments spend `network_compliance`, so they are
already in the set. This by-address selection is the demo's own dataset;
the [case study](case-studies/2026-05-amaru-treasury/case.md) uses a
seed-plus-closure selection for a different purpose.)

```bash
# overlay once (entities, asset, vendors, attestations)
cq-rdf overlay --in docs/case-studies/2026-05-amaru-treasury/overlay.yaml > /tmp/may.ttl

# then one transaction body per line of the by-address selection
xargs -P8 -n1 cq-rdf body --provider blockfrost --token "$BLOCKFROST_PROJECT_ID" \
  < docs/demo/selections.txt >> /tmp/may.ttl
```

Hold the signed CBORs locally instead? Drop the provider and pass paths —
same graph:

```bash
for f in cbor/*.cbor; do cq-rdf body "$f"; done >> /tmp/may.ttl
```

The hand-expanded pair from a moment ago is just two nodes of the lattice
this builds. Now every query ranges over the treasury's whole month at
once.

## Queries — visible SPARQL, auditable numbers

A number you can't see the query for is a number you have to trust. So each
query below is shown **exactly as it runs** (the real `.rq`, not a
paraphrase) next to its result. They go simple → complex, and every one is
a question an operator would actually ask. Run any of them with:

```bash
arq --data /tmp/may.ttl --query docs/demo/queries/<name>.rq
```

### How big is the month?

```sparql
--8<-- "docs/demo/queries/batch-scope.rq"
```

```text
----------------
| transactions |
================
| 88           |
----------------
```

The whole audit surface: 88 transactions. Everything below ranges over
exactly this set.

### Value transferred out of each operator scope

The headline number for an auditor: what *left* each operator scope this
month, by asset. For every transaction T spending one of scope S's
outputs we compute

    per_tx_outflow(S, T)  =  inputs_from_S_in_T  -  outputs_back_to_S_in_T

clamped at zero, then sum across the month. Change UTxOs returning to the
same scope subtract cleanly — so the 3,852,000 ADA that came back to
contingency in [`18d57a4f…`](https://cardanoscan.io/transaction/18d57a4f104df4cc776104ce626958e2110122392e4c4c7671edc8861b48452e)
doesn't inflate its outflow; only the 205,000 that actually left does —
and a co-funder's contribution to a tx only moves the co-funder's own
row, never the other scope's. The scope filter is the `amaru*` prefix:
the two treasuries, the working wallet, and the swap-order intermediate.

<div class="scrollbox" markdown>

```sparql
--8<-- "docs/demo/queries/value-out-per-scope.rq"
```

</div>

```text
-----------------------------------------------------------------------
| scope                               | asset  | outflow        | txs |
=======================================================================
| "amaru-treasury.contingency"        | "ADA"  | 205000.0       | 1   |
| "amaru-treasury.network_compliance" | "ADA"  | 1707820.240061 | 31  |
| "amaru-treasury.network_compliance" | "USDM" | 418750.0       | 7   |
| "amaru.network-wallet"              | "ADA"  | 20.816875      | 33  |
| "amaru.swap-order"                  | "ADA"  | 1707817.860941 | 52  |
-----------------------------------------------------------------------
```

Five rows — and read together they tell the whole flow:

- **205,000 ADA out of `contingency`** — the mid-cycle reserve top-up to
  the operating scope (one transaction; see *How much ADA came in from
  contingency?*).
- **1,707,820 ADA out of `network_compliance` ≈ 1,707,817.86 ADA out of
  `swap-order`** — the same ADA traced through the swap intermediate.
  NC places the orders, swap-order forwards them to SundaeSwap pools as
  the chain converts ADA to USDM. The 2.38 ADA gap is exactly the
  min-UTxO that accompanied the two `cag-payee` USDM payments. The
  leg-by-leg view is *Which transaction spent which? — the swap chain*.
- **418,750 USDM out of `network_compliance`** — the two vendor payments
  through the `cag-payee` bridge (see *What did we pay out, and to
  whom?*).
- **20.82 ADA out of `network-wallet` across 33 txs** — the working
  wallet's *entire* spend for the month is the fee budget. Zero
  principal: `SUM(cardano:hasFee)` over the same 33 txs is exactly
  20.816875 ADA. This is why source-to-destination attribution from the
  graph alone is structurally ambiguous — the working wallet is on every
  transaction as a fee/collateral co-funder, so a row-by-row "who paid
  whom" attribution would have to guess every multi-input tx. The
  per-scope outflow above is honest precisely because it doesn't try.

Destination isn't aggregated in the headline for the same reason. The
drill-downs each pick a transaction shape where the chain itself makes
the recipient unambiguous.

### Where did the USDM end up?

The complementary lens — *destination*-side, USDM only. Resolve each
USDM output to a named scope **through the overlay entities** — so
SundaeSwap pools, batchers and external addresses (which carry no
entity) drop out entirely — and count only what was *not* spent
again inside the batch, which nets out the change that cycled through the
swaps:

<div class="scrollbox" markdown>

```sparql
--8<-- "docs/demo/queries/usdm-received-per-scope.rq"
```

</div>

```text
-----------------------------------------------------
| scope                               | usdm        |
=====================================================
| "amaru.cag-payee"                   | 418750.0    |
| "amaru-treasury.network_compliance" | 6381.618692 |
-----------------------------------------------------
```

Two rows, and they reconcile the entire stablecoin position:
**418,750 USDM** went out the vendor bridge, **6,381.62 USDM** remains in
the operating scope. Their sum, **425,131.62 USDM**, is everything the
treasury ever acquired. No millions, no pools — those were never a
destination, only plumbing the swaps passed through.

### What did we pay out, and to whom?

The 418,750 splits into exactly two on-chain payments:

```sparql
--8<-- "docs/demo/queries/vendor-bridge-disbursements.rq"
```

```text
-----------------------------
| tx_id          | usdm     |
=============================
| "affe90d1fa9a" | 400000.0 |
| "c150d5c5c676" | 18750.0  |
-----------------------------
```

[`affe90d1…`](https://cardanoscan.io/transaction/affe90d1fa9a93b3e2a48009ef80634e9de8428640f5d673e85b002a86399982)
is the **400,000 USDM** payment to **Antithesis**;
[`c150d5c5…`](https://cardanoscan.io/transaction/c150d5c5c67658c8f2a3bc24e16a4852257d46a03224257ac990fcca6f6fde78)
is the **18,750 USDM** payment to **Castellum**. Both land on the same
bridge address, so the *split by vendor* is the operator's knowledge, not
the chain's — and it is exactly what the overlay's vendor declarations and
their backing paperwork make auditable:

```sparql
--8<-- "docs/demo/queries/vendor-attestations.rq"
```

```text
| vendor             | role                  | invoice                | ipfs                       |
==========================================================================================================
| "amaru.antithesis" | "fuzz-testing vendor" | "Invoice INV-635"      | <ipfs://bafkreicnoadl…>    |
| "amaru.castellum"  | "engineering vendor"  | "Contract"             | <ipfs://bafybeib3jef3…>    |
| "amaru.castellum"  | "engineering vendor"  | "Invoice #3508"        | <ipfs://bafybeigy37ui…>    |
| "amaru.castellum"  | "engineering vendor"  | "May2026 cycle review" | <ipfs://bafybeihdmnit…>    |
```

Each vendor's payment is backed by an IPFS-pinned invoice or contract,
queryable right alongside the chain.

### How much ADA came in from contingency?

Mid-cycle the swaps ran short of ADA. The reserve scope topped them up —
a real business event, worth its own question:

<div class="scrollbox" markdown>

```sparql
--8<-- "docs/demo/queries/contingency-inflow.rq"
```

</div>

```text
-----------------------------
| from_tx        | ada_in   |
=============================
| "18d57a4f104d" | 205000.0 |
-----------------------------
```

**205,000 ADA** moved from `amaru-treasury.contingency` into
`network_compliance` in
[`18d57a4f…`](https://cardanoscan.io/transaction/18d57a4f104df4cc776104ce626958e2110122392e4c4c7671edc8861b48452e):
a 4,057,000 ADA reserve UTxO was spent, 3,852,000 returned as change, and
205,000 forwarded to keep the swaps going. Contingency is touched by only
two transactions ever, so this is the complete inflow.

### Which transaction spent which? — the swap chain

The composability proof, and the shape of the whole operation. Each row is
a realised spend edge A`#ix` → B where *both* ends are in the lattice,
joined only through the shared UTxO IRI:

<div class="scrollbox" markdown>

```sparql
--8<-- "docs/demo/queries/spends-graph.rq"
```

</div>

```text
-----------------------------------------------------------------------------------------------
| producer       | ix | consumer       | scope                               | ada            |
===============================================================================================
| "46c11538f39b" | 0  | "18d57a4f104d" | "amaru-treasury.contingency"        | 4057000.0      |
| "64f27254f3c0" | 0  | "dfd355530e2d" | "amaru-treasury.network_compliance" | 1450000.0      |
| "dfd355530e2d" | 2  | "10a5c1dafe7d" | "amaru-treasury.network_compliance" | 1449918.885741 |
| "10a5c1dafe7d" | 2  | "b5716ae98bb4" | "amaru-treasury.network_compliance" | 1449833.102132 |
| "b5716ae98bb4" | 2  | "26ef34aa02ae" | "amaru-treasury.network_compliance" | 1410976.503281 |
| "26ef34aa02ae" | 2  | "f2791967f99a" | "amaru-treasury.network_compliance" | 1372563.060767 |
| "f2791967f99a" | 2  | "2695f20941ac" | "amaru-treasury.network_compliance" | 1293332.892131 |
| "2695f20941ac" | 2  | "b63aa2dd78c2" | "amaru-treasury.network_compliance" | 1215626.254430 |
| "b63aa2dd78c2" | 2  | "5fc04113da63" | "amaru-treasury.network_compliance" | 1137012.611931 |
| "5fc04113da63" | 2  | "5262be893119" | "amaru-treasury.network_compliance" | 1058398.969432 |
| "5262be893119" | 2  | "a38cb99bab8e" | "amaru-treasury.network_compliance" |  979785.326933 |
| "a38cb99bab8e" | 2  | "107e439f247f" | "amaru-treasury.network_compliance" |  901171.684434 |
-----------------------------------------------------------------------------------------------
```

Read it top to bottom and the **sequential swap chain** falls out: each row
consumes the previous swap's change (output `#2` at `network_compliance`)
and the ADA steps down — `dfd35553` → `10a5c1da` (our hero swap) →
`b5716ae9` → `26ef34aa` → … — as each step is converted to USDM. The
contingency top-up (`18d57a4f`, first row) seeds the same pattern on a
second leg. This is the auditor's "show me everything this wallet did, in
order," reconstructed from transactions that were each emitted in complete
isolation.

### What rate did we actually get?

Each SundaeSwap settlement *is* a price tick: a transaction that spends
the swap-order UTxO (the ADA the operator committed) and pays USDM back
to `network_compliance`. Read straight off the chain — no oracle, no
off-chain price — `ada_in` is the swap-order input and `usdm_out` is the
USDM landing on NC in the same tx:

<div class="scrollbox" markdown>

```sparql
--8<-- "docs/demo/queries/swap-rate.rq"
```

</div>

```text
----------------------------------------------------------------------------------------------------------
| tx_id          | ada_in       | usdm_out     | usdm_per_ada               | ada_per_usdm               |
==========================================================================================================
| "02fce56796d2" | 39306.82125  | 10057.846145 | 0.255880425461776561237447 | 3.90807541528564513550729  |
| "04bb08742e4a" | 20411.443265 | 5057.330292  | 0.247769362819724154376205 | 4.036011509330939305001992 |
| "0f9818a51aad" | 38120.299249 | 10016.057124 | 0.262748648917354672889074 | 3.805918714027493998944968 |
| …              | …            | …            | …                          | …                          |
| "ee9d02118fce" | 38120.299249 | 10014.718939 | 0.262713544654629476568304 | 3.806427267823696634648011 |
----------------------------------------------------------------------------------------------------------
```

**52 settlements** across the month. Aggregated they reconcile the entire
position: **1,654,998 ADA spent**, **425,131.62 USDM received**, average
**0.256877 USDM/ADA** (or **3.8929 ADA/USDM**). Per-leg the rate spreads
~0.243 → 0.264 USDM/ADA as the pool moved through the month. The
425,131.62 USDM in the right column ties out exactly to *Where did the
USDM end up?* above — the same coins, seen at the moment they were
created.

## Reproduce it yourself

Every command on this page runs against the published binaries. The
canonical end-to-end pipe lives in each case study's `README.md` — for
the May 2026 walk-through above:

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider blockfrost < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl \
  | cq-rdf blueprint --blueprints blueprints/ \
  | cq-rdf shacl --shapes shapes/ \
  > package.ttl
```

Then `arq --data package.ttl --query <some-query>.rq` for any SPARQL on
this page. The full case-study package, including `overlay.yaml`,
`selections.txt`, `blueprints/`, and `shapes/`, is in
[`docs/case-studies/2026-05-amaru-treasury/`](case-studies/2026-05-amaru-treasury/case.md).

## Closing — write your own query

The queries above are examples, not the ceiling. The lattice is plain RDF,
so the fastest way to ask your own question is to hand an LLM the
vocabularies and describe what you want in English.

Two ontology files cover the lattice end-to-end — paste both alongside
your question:

- [`vocab/cardano/transactions.ttl`](https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano/transactions.ttl)
  defines the ledger-level vocabulary: every term the body emitter
  uses (`cardano:hasOutput`, `cardano:atAddress`,
  `cardano:hasAssetValue`, `cardano:fromTxOutRef`, …).
- [`vocab/treasury/overlay.ttl`](https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury/overlay.ttl)
  defines the treasury-overlay vocabulary used by `cq-rdf overlay` when
  the case study imports it: `treasury:OffChainEntity`,
  `treasury:Attestation`, `treasury:paidVia`, `treasury:attests`,
  `treasury:role`, `treasury:ipfs`.

Together they cover everything in `/tmp/may.ttl` — the body triples
plus the operator's overlay. A prompt that works:

> Here are two RDF vocabularies for a Cardano on-chain lattice with a
> treasury overlay *(paste `transactions.ttl` and `overlay.ttl`)*. Over
> a Turtle graph of merged transactions using these vocabularies, write
> a SPARQL query that answers: **\<your question>**. Operator scopes
> are `cardano:Entity` nodes carrying `rdfs:label` and `cardano:bech32`;
> join outputs to them by bech32 to work in named scopes. Off-chain
> vendors paid via a bridge address are `treasury:OffChainEntity`
> nodes carrying `treasury:paidVia` and `treasury:attests`.

Three questions to start from — each a real treasury question, each a few
lines of SPARQL:

- *"Every payment to a named vendor, with the backing invoice or contract
  from its attestations."*
- *"Which transactions spent the treasury's own change — the internal swap
  chain — and how did the ADA balance step down?"*
- *"Total ADA that entered the operating scope from the contingency
  reserve."*

If the generated query references a term that isn't in the vocabulary,
that's your signal it guessed — paste the error back and it will correct
against the real schema.
