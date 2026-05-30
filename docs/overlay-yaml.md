# overlay.yaml

`cq-rdf overlay --in FILE` reads an operator-authored RDF overlay and
emits overlay-only Turtle. The overlay gives stable names to on-chain
identifiers, registers optional CIP-57 blueprints for typed datum and
redeemer decoding, and attaches off-chain evidence to named entities.

The loader accepts `.yaml`, `.yml`, and canonical `.ttl` files. YAML is
the authoring format operators normally edit; Turtle is the canonical
overlay format emitted by the loader.

By convention case studies name this file `overlay.yaml` and ship it
alongside their `selections.txt`, `blueprints/`, and `shapes/`. The
deprecated `tx-graph --rules` entry point reads the same format; new
work should target [`cq-rdf overlay`](cq-rdf.md#overlay).

## Shape

```yaml
imports:
  - treasury        # vocab import (built-in short name)
  - common.yaml     # file import (legacy DFS composition)

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

Top-level keys consumed by `cq-rdf overlay`:

| Key | Meaning |
|--|--|
| `imports` | Vocabularies (bare short name or `{iri:, as:}` object) declaring non-cardano keys, and/or relative YAML/Turtle files to load before the current file. |
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
string be declared under multiple Cardano leaf types. The case-study
[overlay.yaml](case-studies/2026-05-amaru-treasury/overlay.yaml) is a
worked example exercising every entity shape.

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

Paths are relative to the overlay file. The referenced `script:` must
name an entity with a `PaymentScript` identifier. When `cq-rdf
blueprint` (the CIP-57 typed-decode pass) encounters a datum or
redeemer locked by that script, it emits typed predicates from the
blueprint constructor and field names. Decode failures keep the raw
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

The `imports:` block carries two orthogonal kinds of entry, both
classified at parse time by the entry's shape:

* **Vocabulary imports** opt the overlay in to a non-cardano
  ontology so its keys become usable on entity / attestation
  entries. Two authoring forms:

  ```yaml
  imports:
    - treasury                            # built-in short name
    - { iri: https://example.com/foo/vocab#, as: foo }  # inline
  ```

  The built-in registry currently contains one entry: `treasury` →
  `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#`.
  Other short names are rejected with `UnknownImport` unless the
  operator supplies an inline `{iri:, as:}` object.

  Treasury-overlay keys (`paid-via`, `role`, `attests`, `ipfs`) are
  available only when `imports: [treasury]` is present; using them
  without the import is a `MissingImport` error pointing the
  operator at the missing vocabulary.

  Keys from inline-imported ontologies must be written in
  explicit-prefix form (`foo:custom-key:`); the loader has no
  schema for them.

  When two imported vocabularies claim the same local key the
  parser refuses to guess and demands the explicit-prefix form
  (`treasury:role:` or `foo:role:`).

  The emitted overlay TTL declares one `owl:imports` per resolved
  vocabulary plus the implicit cardano ontology, so downstream
  consumers can resolve vocab provenance:

  ```turtle
  <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/manifest/<fixture>#>
    a owl:Ontology ;
    owl:imports <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano/transactions> ,
                <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury/overlay> .
  ```

* **File imports** are relative YAML/Turtle paths the loader reads
  before the current file. An entry is classified as a file import
  when its string contains a `/` path separator or ends in `.yaml`
  / `.yml` / `.ttl`.

  File imports are resolved depth-first, then deduplicated. Child
  files are loaded before the file that imports them. Cycles,
  missing files, absolute paths, and HTTP(S) imports are errors.

  If two files declare the same identifier, the first declaration
  owns the identifier blank node and later entities reference it.
  If two blueprint entries target the same script hash, the first
  one wins and the loader emits a warning.
