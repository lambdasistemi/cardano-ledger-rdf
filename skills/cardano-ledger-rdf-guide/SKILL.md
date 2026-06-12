---
name: cardano-ledger-rdf-guide
description: >-
  Onboarding and navigation guide for the cardano-ledger-rdf repository:
  the Cardano Conway transaction → RDF graph engine and its two
  executables, cq-rdf and tx-view. Load this when working in this repo or
  answering questions about it — emitting a transaction as RDF/Turtle/
  JSON-LD, the cq-rdf subcommands (overlay, body, blueprint, shacl), the
  tx-view packaged views (cli-tree, asset-flow, entity-occurrences,
  json-ld), the operator overlay.yaml format (entities, blueprints,
  attestations, imports, keys/bytes, pool, drep), CIP-57 typed datum/
  redeemer decode, SHACL validation, the koios/blockfrost/http CBOR
  providers and --token/--provider/--url flags, the cardano: and
  treasury: vocabularies under vocab/, the deprecated tx-graph compat
  symlink, or how cardano-ledger-rdf relates to cardano-tx-tools. Triggers
  include the module prefixes Cardano.Tx.Graph.Emit, Cardano.Tx.View,
  Cardano.Tx.Decode, Cardano.Tx.Blueprint; the just recipes (just unit,
  just ci, just build-docs); errors like RulesLoadError, EmitError,
  ViewError, "parent tx not in lattice", cardano:decodeError; and the
  paths app/tx-graph/Main.hs (which builds cq-rdf), app/tx-view/Main.hs,
  vocab/cardano/transactions.ttl, and docs/case-studies/.
---

# cardano-ledger-rdf guide

`cardano-ledger-rdf` emits a Cardano Conway transaction as a
deterministic RDF graph and projects it through packaged views. Two
executables: `cq-rdf` (four pure subcommands — `overlay`, `body`,
`blueprint`, `shacl`) and `tx-view` (packaged graph projections). The
generic `cardano:` engine plus app-shipped RDF assets (overlay,
blueprints, shapes) give transaction authors a pre-sign gate and
auditors a lattice classifier. Full prose lives in `docs/` and at
<https://lambdasistemi.github.io/cardano-ledger-rdf/>.

## Repository map

| Path | Purpose |
|---|---|
| `app/tx-graph/Main.hs` | **Builds the `cq-rdf` executable** (subparser: `overlay`/`body`/`blueprint`/`shacl`). The same binary also runs as the legacy `tx-graph` when invoked under that name (`getProgName`). |
| `app/tx-view/Main.hs` | The `tx-view` executable: `--graph FILE\|-`, `--view NAME`, `--out FILE`. |
| `src/Cardano/Tx/Decode.hs` | Conway tx CBOR decode; `ConwayTx`, `decodeConwayTxInput`, `decodeBech32Address`. |
| `src/Cardano/Tx/Blueprint.hs` | CIP-57 blueprint JSON parsing; `parseBlueprintJSON`, `resolveBlueprintSchema`. |
| `src/Cardano/Tx/Graph/Emit.hs` + `Emit/**` | The body walker and RDF emission. Serializers in `Emit/Serialize/{Turtle,JsonLd}.hs`; per-field emitters `Emit/{Certificate,GovAction,NativeScript,Metadatum,Witness}.hs`; typed decode `Emit/Blueprint.hs`; entity slug lookup `Emit/Lookup.hs`; DSL `Emit/{Monad,Triple,Project}.hs`; vocab `Emit/{Vocab,VocabExport}.hs`. |
| `src/Cardano/Tx/Graph/Provider.hs` | HTTP CBOR fetchers: `koios`, `blockfrost`, `http`; `fetchCbor`, `ProviderConfig`, `parseProviderArg`. |
| `src/Cardano/Tx/Graph/Resolve.hs`, `Resolve/Web2.hs` | Resolver chain for spending/reference/collateral inputs. |
| `src/Cardano/Tx/Graph/Rules/Load.hs` + `Rules/Load/**` | Operator-overlay loader. YAML parser `Rules/Load/Parse/Yaml.hs` (`parseLeafType`, entity shapes); Turtle `Parse/Turtle.hs`; vocab imports `Imports.hs`; `Types.hs` (`LeafType`, `RulesLoadError`); `Naming.hs`, `Bech32.hs`, `Emit/Overlay.hs`, `Resolve/Imports.hs`. |
| `src/Cardano/Tx/View.hs` + `View/**` | Packaged views; `parseViewName`, `renderView`, `knownViewNames`. One module per view: `View/{CliTree,AssetFlow,EntityOccurrences,JsonLd,Turtle}.hs`. |
| `vocab/cardano/transactions.ttl` | `cardano:` ontology (source of truth; mirrored to the docs site). |
| `vocab/treasury/overlay.ttl` | `treasury:` accountability-overlay ontology. |
| `views/*.rq` | Packaged SPARQL views (`cli-tree`, `asset-flow`, `entity-occurrences`, `json-ld`, plus `no-stub-triples.rq` as a contract query — not a `--view` name). |
| `rules/amaru-treasury.yaml` | Example operator overlay. |
| `docs/` | MkDocs site: `cq-rdf.md`, `tx-view.md`, `overlay-yaml.md`, `vocab.md`, `demo.md`, `case-studies/`. |
| `specs/`, `.specify/` | Spec Kit feature specs + constitution. |
| `scripts/` | `validate-ttl.py`, `owl-smoke.py`, `vocab-accessibility.py`, demo + release helpers. |
| `test/` | hspec suite + `test/fixtures/` (golden `tx-graph/`, `views/`). |
| `nix/`, `flake.nix`, `justfile`, `gate.sh` | Build tooling and gates. |

## Build, test, run

All dev builds use `-O0`; drive everything through `just` inside
`nix develop`.

```bash
nix develop --quiet -c just build          # cabal build all -O0
nix develop --quiet -c just unit           # unit suite (wires CQ_RDF_EXE/TX_VIEW_EXE)
nix develop --quiet -c just unit match="WitnessSpec"   # filtered
nix develop --quiet -c just ci             # build + unit + smokes + vocab + fmt + lint
nix flake check --no-eval-cache            # flake checks (incl. vocab gates)
just vocab-validate && just vocab-owl-smoke && just vocab-accessibility
nix run .#cq-rdf  -- --help                # run without building
nix run .#tx-view -- --help
just build-docs                            # mkdocs build --strict
```

## Navigating the code

- **CLI entry points:** `app/tx-graph/Main.hs` (`cq-rdf`) and
  `app/tx-view/Main.hs` (`tx-view`). Note the directory name `tx-graph`
  is historical — that source builds the `cq-rdf` binary.
- **Library entry points:** the `exposed-modules` in
  `cardano-ledger-rdf.cabal` — `Cardano.Tx.Graph.Emit`,
  `Cardano.Tx.View`, `Cardano.Tx.Blueprint`, `Cardano.Tx.Decode`,
  `Cardano.Tx.Graph.Provider`, `Cardano.Tx.Graph.Resolve(.Web2)`,
  `Cardano.Tx.Graph.Rules.Load(.Imports)`.
- **Emit pipeline:** `emit tx utxo entities blueprints` →
  `EmittedGraph` → `serialize*` (`Emit.hs`). Per-field logic dispatches
  into `Emit/Certificate.hs`, `Emit/GovAction.hs`, etc.
- **Add a packaged view:** extend `ViewName`/`parseViewName` in
  `View.hs`, add `View/<Name>.hs` + `views/<name>.rq` + a golden fixture
  under `test/fixtures/views/`.
- **Overlay keys/shapes:** `Rules/Load/Types.hs` (`LeafType`) and
  `Rules/Load/Parse/Yaml.hs` (`parseLeafType`, `parseSingleShape` for
  `from-address`/`script`/`asset`/`pool`/`drep`/`keys`+`bytes`).
- **Provider endpoints:** `Graph/Provider.hs`.
- **Haddock `>>>` examples** are mirrored as expectations in
  `test/Cardano/Tx/Doc/ExamplesSpec.hs`; keep them in sync.

## Using cq-rdf and tx-view

Verified against `app/tx-graph/Main.hs` and `app/tx-view/Main.hs`:

```bash
# overlay: operator YAML/Turtle → overlay-only Turtle
cq-rdf overlay --in overlay.yaml > overlay.ttl

# body: one Conway tx → body TTL (file, stdin, or fetched txid)
cq-rdf body tx.cbor                                  # local CBOR (--provider file default)
cq-rdf body -                                        # one tx from stdin
cq-rdf body --provider koios <txid>                  # free tier, optional --token
cq-rdf body --provider blockfrost --token "$BLOCKFROST_PROJECT_ID" <txid>   # token REQUIRED
cq-rdf body --provider http --url https://indexer/ <txid>
cq-rdf body tx.cbor --format json-ld                 # turtle (default) | json-ld

# blueprint: append CIP-57 typed datum/redeemer triples (idempotent)
cat overlay.ttl body.ttl | cq-rdf blueprint --blueprints blueprints/ > package.ttl

# shacl: validate; exits non-zero on violation (needs Apache Jena `shacl` on PATH)
cq-rdf shacl --shapes shapes/ < package.ttl
cq-rdf shacl --shapes shapes/ --severity warning < package.ttl

# tx-view: project a canonical Turtle graph
cq-rdf body --provider koios <txid> | tx-view --graph - --view cli-tree
tx-view --graph lattice.ttl --view json-ld --out lattice.jsonld
```

The canonical lattice pipe (author gate / auditor classifier) is one
shell pipe — `overlay` once, `body` per txid (parallelize with
`xargs -P`), `blueprint`, then `shacl` as a gate or `arq` for SPARQL.
`cq-rdf body --provider` is the only network boundary; everything else is
offline. Diagnostics (e.g. `parent tx not in lattice`) go to stderr so
stdout stays clean for the next pipe stage.

## Answering questions

| User asks | Where the answer lives |
|---|---|
| Install / which artifacts | `README.md` Install; assets are versioned `cq-rdf-<ver>-<arch>.{AppImage,deb,rpm,tar.gz}`; Homebrew tap `lambdasistemi/tap`. |
| What `cq-rdf` does / the four subcommands | `docs/cq-rdf.md` |
| Overlay YAML format, entity shapes, `keys:` labels | `docs/overlay-yaml.md`; source `Rules/Load/Parse/Yaml.hs` |
| Which views `tx-view` has | `docs/tx-view.md`; source `View.hs` (`knownViewNames`) |
| Provider endpoints / auth / `--token` | `docs/cq-rdf.md` (body table); source `Graph/Provider.hs` |
| Vocabulary, namespaces, SPARQL prefixes | `docs/vocab.md`; `vocab/cardano/transactions.ttl`, `vocab/treasury/overlay.ttl` |
| End-to-end worked example | `docs/demo.md`; `docs/case-studies/2026-05-amaru-treasury/` |
| Relationship to `cardano-tx-tools` | `README.md` Architecture section |
| Why `app/tx-graph/` builds `cq-rdf` | `app/tx-graph/Main.hs` header; `tx-graph` is the legacy compat name selected by `getProgName`. |

When presenting the project to a user, lead with the two-persona framing
(author pre-sign gate vs. auditor classifier on one graph), name the two
binaries, and point at `docs/demo.md` for a runnable walk-through. Verify
any command against the source before claiming it works — the docs above
are kept in sync with `app/**/Main.hs`.
