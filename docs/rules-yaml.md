# rules.yaml

`tx-graph --rules FILE` loads an operator-authored RDF overlay. The
overlay gives stable names to on-chain identifiers, registers optional
CIP-57 blueprints for typed datum and redeemer decoding, and attaches
off-chain evidence to named entities.

The loader accepts `.yaml`, `.yml`, and canonical `.ttl` files. YAML is
the authoring format operators normally edit; Turtle is the canonical
overlay format emitted by the loader.

## Shape

```yaml
imports:
  - common.yaml

entities:
  - name: amaru-treasury.network_compliance
    from-address: addr1...

  - name: amaru.swap.v2
    script: fa6a58bbe2d0ff05534431c8e2f0ef2cbdc1602a8456e4b13c8f3077

  - name: usdm
    asset:
      policy: c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad
      name: USDM

blueprints:
  - script: amaru.swap.v2
    datum: ./blueprints/swap-v2-datum.cip57.json

attestations:
  - ipfs: ipfs://baf...
    label: Invoice INV-635
    of: amaru-treasury.network_compliance
```

Top-level keys consumed by `tx-graph`:

| Key | Meaning |
|--|--|
| `imports` | Relative YAML/Turtle files to load before the current file. Absolute and HTTP imports are rejected. |
| `entities` | Operator names for addresses, scripts, policies, assets, and off-chain parties. |
| `blueprints` | CIP-57 datum blueprints keyed by a named script entity. |
| `attestations` | IPFS-anchored evidence linked to a named entity. |

Rule files in this repository should stay within this graph-overlay
surface. Downstream presentation configuration belongs in downstream
tools that consume the emitted RDF.

## Entities

Each entity must have a `name`. The loader slugifies it to a stable IRI
local part by lowercasing, replacing non-alphanumeric characters with
`_`, collapsing repeated underscores, and rejecting empty or leading
digit slugs.

Supported identifier shapes:

```yaml
entities:
  - name: alice
    from-address: addr1...

  - name: swap-validator
    script: fa6a58bbe2d0ff05534431c8e2f0ef2cbdc1602a8456e4b13c8f3077

  - name: usdm
    asset: { policy: c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad, name: USDM }

  - name: usdm-control
    keys: [PaymentScript, Policy]
    bytes: c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad

  - name: io.submission-tx
    keys: [TxId]
    bytes: 73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762

  - name: io.proposal.developer-experience
    keys: [GovActionId]
    bytes: 73e171a4c0730b4b59ecae271ab89f12a9d56360b02920e1f95107dbdc1d6762:0
```

`from-address` decomposes Conway addresses into payment and stake
credentials. `script` creates a `PaymentScript` identifier. `asset`
stores `policy ++ hex(assetName)`. `keys` plus `bytes` lets one byte
string be declared under multiple Cardano leaf types.

Supported `keys:` labels are `PaymentKey`, `PaymentScript`, `StakeKey`,
`StakeScript`, `DRepKey`, `DRepScript`, `PoolId`, `Policy`,
`AssetClass`, `TxId`, and `GovActionId`.

Most key labels use 28-byte hex in `bytes:`. `TxId` uses a 32-byte
transaction hash. `GovActionId` uses `<txid_hex>:<index>`, where
`txid_hex` is the 32-byte transaction hash of the governance action's
submission transaction and `index` is the decimal action index in that
transaction.

An off-chain entity may omit on-chain identifiers when it references a
paying entity:

```yaml
entities:
  - name: amaru.cag-payee
    from-address: addr1...
  - name: amaru.antithesis
    label: Antithesis Operations LLC
    role: fuzz-testing vendor
    paid-via: amaru.cag-payee
```

## Blueprints

`blueprints:` registers a CIP-57 JSON file for a named script entity:

```yaml
blueprints:
  - script: amaru.swap.v2
    datum: ./blueprints/swap-v2-datum.cip57.json
```

Paths are relative to the rules file. The referenced `script:` must name
an entity with a `PaymentScript` identifier. When `tx-graph` encounters a
datum or redeemer locked by that script, it emits typed predicates from
the blueprint constructor and field names. Decode failures keep the raw
bytes and add `cardano:decodeError`.

## Attestations

`attestations:` links an IPFS artefact to an entity:

```yaml
attestations:
  - ipfs: ipfs://bafkreicnoadlgnc6cqxggxboho7yt532lkonxcusj3ndsxdnv5szyswyam
    label: Invoice INV-635
    of: amaru.antithesis
```

The `of:` value is the referenced entity name; it is slugified the same
way as `entities[].name`.

## Imports

Imports are resolved depth-first, then deduplicated. Child files are
loaded before the file that imports them. Cycles, missing files, absolute
paths, and HTTP(S) imports are errors.

If two files declare the same identifier, the first declaration owns the
identifier blank node and later entities reference it. If two blueprint
entries target the same script hash, the first one wins and the loader
emits a warning.
