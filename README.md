# cardano-ledger-rdf

`cardano-ledger-rdf` turns any Cardano transaction into a deterministic
RDF graph that two people can actually *use*:

- **Transaction authors** — before you sign or submit, check that a
  transaction conforms to your application's rules, and read the result
  in your application's own words ("contingency disburse: 4/4 owners ✓,
  destination off allowlist ✗") instead of a ledger error code. A
  non-conforming transaction never reaches a co-signer.
- **Auditors** — query and classify what already happened on-chain
  across a whole lattice of transactions, using the same application
  vocabulary and the same constraints. A transaction that conforms was
  built by the canonical pipeline; one that violates is foreign or
  off-spec — anomaly detection for free.

Both UXes run on the **same artefact** — the RDF graph of the
transaction — and the **same generic engine**. What makes them speak a
particular application's language is a small bundle of **RDF assets that
the application developer ships and parametrizes**:

| Asset | Slot | Parametrizes |
|---|---|---|
| **overlay** | `cq-rdf overlay` | the app's entities, labels, and attestations — operator/app reference data |
| **blueprints** | `cq-rdf blueprint` | typed datum/redeemer decode (CIP-57) so contract fields are queryable |
| **metadata schemas** | `cq-rdf metadata` *(landing)* | typed interpretation of the app's transaction-metadata labels |
| **shapes** | `cq-rdf shacl` | SHACL conformance + hygiene constraints — the author gate and the auditor classifier |

The engine is **generic Cardano RDF**; the assets are the **app's
parametrization**. An application developer ships them the way they ship
a policy id; from then on any author or auditor gets the UX for free,
with no bespoke tooling. The [2026-05 Amaru treasury](docs/case-studies/2026-05-amaru-treasury/README.md)
case study is the worked canary — its `overlay.yaml`, `blueprints/`, and
`shapes/` are exactly this asset bundle.

## The two UXes, on one pipeline

The author gate and the auditor classifier are the *same* four-stage
pipe, pointed at different inputs and read with different intent:

```bash
# emit the app's overlay, fetch one body per txid, type the datums,
# then validate against the app's shapes:
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider blockfrost < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl \
  | cq-rdf blueprint --blueprints blueprints/ \
  > package.ttl
cq-rdf shacl --shapes shapes/ < package.ttl     # author gate: exits non-zero on violations
arq --data package.ttl --query my.rq            # auditor: query the lattice via Apache Jena or any SPARQL engine
```

- **Author (pre-sign):** point `cq-rdf body` at the transaction you just
  built; `cq-rdf shacl --shapes` is a gate — it exits non-zero with a
  readable, domain-level violation, so you fix it before circulating.
- **Auditor (post-hoc):** point `cq-rdf body` at a lattice of on-chain
  txids; the *same* shapes become a classifier, and the app's SPARQL
  queries answer cross-transaction questions.

`cq-rdf body --provider` is the only network boundary in the core
pipeline: it fetches CBOR by txid from a koios / blockfrost /
generic-HTTP indexer. With `--provider file` (the default) every stage
is an offline transformation over local files.

## Tools

| Tool | Role |
|------|------|
| `cq-rdf` | The runtime. Four composable subcommands — `overlay`, `body`, `blueprint`, `shacl` — each a pure function with a narrow IO contract. |
| `tx-view` | Project a generated Turtle graph through packaged views (`cli-tree`, `asset-flow`, `entity-occurrences`, `json-ld`). |
| `tx-graph` | Deprecated one-release compatibility symlink for the old transaction-body CLI shape. |

Generic transaction applications — diffing, inspecting, signing,
validating, load generation — belong in `cardano-tx-tools`, a downstream
consumer that depends on this repository when backed by `cq-rdf body`
output. This repository's boundary is graph/RDF: the engine, the
vocabulary, and the asset slots an application parametrizes.

`tx-graph --rules X` is deprecated for one release. Use
`cq-rdf overlay --in X` for the operator overlay and concatenate that
with one or more `cq-rdf body ...` outputs. See
[docs/tx-graph.md](docs/tx-graph.md) for the migration table.

## Vocabulary

Two namespaces, each with a published ontology — the generic core and an
example explicit extension:

| Prefix | Layer |
|---|---|
| `cardano:` | Ledger primitives (`Transaction`, `Output`, `Datum`, metadata, …). The generic core. |
| `treasury:` | An accountability overlay (`OffChainEntity`, `paidVia`, `attests`, …). An explicit, app-shaped extension. |

The split is a principle, not an accident: the core models Cardano, never
a single application's business semantics; an app's meaning lives in its
assets and its own extension namespace. See [docs/vocab.md](docs/vocab.md).

## Library

| Module family | Role |
|---------------|------|
| `Cardano.Tx.Graph.*` | RDF graph emission, operator entity overlays, canonical Turtle/JSON-LD serialization. |
| `Cardano.Tx.View.*` | Packaged graph projections used by `tx-view` and future HTTP services. |
| `Cardano.Tx.Blueprint` | CIP-57 blueprint parsing for typed datum/redeemer predicates. |
| `Cardano.Tx.Decode` / `Cardano.Tx.Graph.Resolve` | Shared transaction decoding and resolved-input lookup for RDF tools. |

## Release

Release automation packages only the RDF tools:

```bash
nix build .#cq-rdf-linux-release-artifacts
nix build .#tx-graph-linux-release-artifacts
nix build .#tx-view-linux-release-artifacts
```

Darwin/Homebrew artifacts are built by the corresponding GitHub Actions
workflows for the same executables.

### Runtime dependencies (Darwin/Homebrew installs)

The Linux release artifacts (AppImage / `.deb` / `.rpm`) bundle a complete
runtime closure, including Apache Jena. The Darwin Homebrew tarball ships
only the `cq-rdf` (and renamed `tx-graph`) binary plus its native dylibs —
it does NOT bundle the Java runtime or Apache Jena. The `cq-rdf overlay`,
`cq-rdf body`, and `cq-rdf blueprint` subcommands are pure Haskell and
need no extra dependencies. The `cq-rdf shacl` subcommand and the
`arq`-based SPARQL examples above require Apache Jena on `PATH`. On macOS:

```bash
brew install jena
```

Inside `nix develop` the project's flake shell already provides Apache
Jena, so this note only applies to Homebrew-installed `cq-rdf`.

## Develop

```bash
nix develop --quiet -c just build
nix develop --quiet -c just ci
nix flake check --no-eval-cache
```

Specs and per-feature design notes live under `specs/`.

## License

[Apache 2.0](LICENSE).
