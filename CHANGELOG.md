# Changelog

## Unreleased

## [0.4.1.0](https://github.com/lambdasistemi/cardano-ledger-rdf/compare/v0.4.0.0...v0.4.1.0) (2026-07-13)

### Features

* split tx-rdf-core package ([c283f1f](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/c283f1f3dee583330558cfbdc34d458f5956eaa9))
* emit flat txoutref join keys ([1ef103a](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/1ef103a923dc64fae7ef94cafd6e18665fefbb91))
* emit per-entity network literals ([1c2e893](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/1c2e893d114fe335548b9cd9ec3e8538254c3573))
* type voting-procedure voter identifiers ([6a8d60d](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/6a8d60d41ce3af69f3ce2f4aa8a69ce7032fda73))

## [0.4.0.0](https://github.com/lambdasistemi/cardano-ledger-rdf/compare/v0.3.0.0...v0.4.0.0) (2026-06-10)

This release completes the builder-ownership inversion ([#86](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/86)): the transaction-builder DSL now has a single home in `cardano-tx-tools:tx-build`, and this library's public API is purely RDF.

### Breaking Changes

* **Builder modules removed from the public API**: `Cardano.Tx.Build`, `Cardano.Tx.Balance`, `Cardano.Tx.Evaluate`, `Cardano.Tx.Witnesses`, `Cardano.Tx.Deposits`, `Cardano.Tx.Scripts`, `Cardano.Tx.Credentials`, and `Cardano.Tx.Inputs` are deleted ([#88](https://github.com/lambdasistemi/cardano-ledger-rdf/pull/88)). Downstream consumers should depend on the `cardano-tx-tools:tx-build` public sub-library, which exposes the same modules as the canonical copy.
* **`Cardano.Tx.Ledger` removed**: the `ConwayTx` type alias now lives in `Cardano.Tx.Decode`; import it from there.
* **Integration policy**: `cardano-tx-tools` consumes `cq-rdf` output at the CLI boundary (pipes); it never links this library. Recorded in both READMEs to keep the cross-repo dependency graph acyclic.

### Features

* **release:** use shared linux artifacts ([65c74a5](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/65c74a5047396c3ab505b3b614a754d59ae295e9))
* **emit:** decode transaction metadata into generic cardano: RDF ([e115fc7](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/e115fc78a14236aa786f569d93749d26a20bd745))

### Bug Fixes

* **emit:** trace vocab against the owned ontology, drop kmaps-pin allowlist ([27b68fc](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/27b68fc0f8eda2f8b2f66db7728781888e60bbea))
* **checks:** drop deleted builder modules from haddock coverage ([72d2685](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/72d2685ee4ca1dd327ae370d038be86c40e1bb98))

## [0.3.0.0](https://github.com/lambdasistemi/cardano-ledger-rdf/compare/v0.2.5.0...v0.3.0.0) (2026-05-30)

This release lands epic [#66](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/66) — the runtime/app separation. The on-disk shape every operator depends on changes; see Breaking Changes.

### Breaking Changes

* **CLI rename**: `tx-graph` → `cq-rdf` with four subcommands (`overlay` / `body` / `blueprint` / `shacl`). The old `tx-graph` name remains for one release as a compatibility wrapper (a Darwin-friendly unwrapped binary that dispatches to legacy mode via `getProgName`); invoking `tx-graph --rules X` emits a stderr deprecation warning pointing at the new pipe.
* **Vocab split**: `cardano:` namespace retains only ledger primitives. Treasury overlay predicates moved to `treasury:` (`treasury:OffChainEntity`, `treasury:Attestation`, `treasury:paidVia`, `treasury:attests`, `treasury:ipfs`, `treasury:role`). Existing SPARQL queries that used `cardano:paidVia` etc. must rewrite their prefixes.
* **Overlay YAML**: operator-authored YAML files (formerly `rules.yaml`) now require an `imports:` block when they use non-cardano predicates. Without `imports: [treasury]`, keys like `paid-via:` fail the parser with `MissingImportForKey`. Emitted overlay TTL declares `owl:imports` for each resolved ontology.
* **Case-study package layout**: every case study migrated to `overlay.yaml` + `README.md` + optional `blueprints/` + optional `shapes/`. The per-case `pipeline.sh` orchestrator scripts are deleted; reproduce is a documented Unix pipe (no `cq-rdf build` meta-orchestrator and no `recipe.yaml` — both explicitly rejected during design).

### Features

* **vocab:** split treasury overlay predicates out of cardano namespace (#67) ([0e06dc0](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/0e06dc0214555ff1cedadec19f0f9ab738e2a0b2))
* **cli:** split tx-graph into cq-rdf subcommands (#68) ([2a6aff6](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/2a6aff65cdb2288f471fce18b2aa1da311e85ebe))
* **rules:** overlay YAML imports + emitted owl:imports (#72) ([94c1c24](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/94c1c24e4223378333762f5d7f39f92cc97cdf45))
* **shapes:** SHACL invariants first-class — self-swap + attested-disbursement (#71) ([3bd45fa](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/3bd45fa31a7003447b572ea13a1a6296b543e97f))

### Bug Fixes

* **release:** Darwin aarch64 cq-rdf tarball self-contained (no Nix store dangling refs) (#74) ([ceb7a66](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/ceb7a66802321d3abf8b1b630ff08c0e20e5545f))

### Documentation

* **case-studies:** migrate to declarative package layout, delete every `pipeline.sh`; canonical reproduce pipe documented per case-study README (#73) ([1872753](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/1872753))
* **docs:** ontology accessibility + vocab tests; new `vocab/{cardano,treasury}/index.md` landing pages so declared base IRIs dereference instead of 404; new `scripts/vocab-accessibility.py` self-testing gate wired as `nix build .#checks.x86_64-linux.vocab-accessibility`; reproduce pipe smoke against real Blockfrost mainnet for May 2026 case study (#75) ([8d0eeba](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/8d0eeba))

## [0.2.5.0](https://github.com/lambdasistemi/cardano-ledger-rdf/compare/v0.2.4.0...v0.2.5.0) (2026-05-29)

### Features

* **demo:** end-to-end pipeline demo with rules + blueprints + cross-tx SPARQL on real mainnet (#62) ([cd7a9dd](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/cd7a9dd3d86572a3623e69145d3f632ed27e7e1b))

### Documentation

* **demo:** per-scope value-out and per-settlement swap-rate queries; wallet outflow ties to `SUM(cardano:hasFee)` exactly (#64) ([9f15abd](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/9f15abdea76bfa5804e9b718d4b4c2da84088d28))
* **case-studies:** replace fantasies with verified SPARQL — drop fabricated `cardano:hasLatticeRole`, fix Q5 `amaru:` prefix and Q6 truncated bech32, correct fee narrative (`71ff129b` 1.572508 ADA, not the 4-of-4 contingency disburse), label sidecar analyses (#64) ([9f15abd](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/9f15abdea76bfa5804e9b718d4b4c2da84088d28))

## [0.2.4.0](https://github.com/lambdasistemi/cardano-ledger-rdf/compare/v0.2.3.0...v0.2.4.0) (2026-05-29)

### Features

* **rules:** TxId + GovActionId leaf types for keys+bytes shape (#38) ([ab11c43](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/ab11c43131a0c94865d48dcd31463ad33e85a326))
* **vocab:** port TTL + OWL 2 RL validation gate from cardano-knowledge-maps (closes #40) (#43) ([0df38e5](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/0df38e59181ef56fba71c44b8e5220657bf75107))
* **tx:** typed native_script tree walker (multisig + timelocks) (#48) ([02a9f04](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/02a9f04fc166e815c4a860b8f99ff39d378611fb))
* **tx:** emit auxiliary data body + isValid flag (#51) ([6933c45](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/6933c45cd91197f05adaa673b928dfcbe66a8065))
* **tx:** typed certificate tree walker (stake + DRep + pool + committee) (#52) ([8257e48](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/8257e48fa240612db7636d85eede823509e592bc))
* **tx:** emit body fields 21 (current_treasury_value) and 22 (donation) (#53) ([3e264be](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/3e264bed40702e4a4e93c6bcb4f616c2025c5834))
* **tx:** typed governance-action walker (parameter_change + update_committee + new_constitution + hard_fork_initiation) (#54) ([8a2e95c](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/8a2e95c78d19e8a72c8fc3d5d09c2502b18593c1))
* **emit:** promote content-addressed bnodes to IRIs for cross-response composability (#57) ([4ef6b1a](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/4ef6b1a46d721411616c6b2f12c943d995502ad4))
* **tx-graph:** remove batch mode; single-CBOR-in, single-Turtle-out (closes #59) (#60) ([ba271f7](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/ba271f7653bc1d1bc8049141e89759af13766b90))

## [0.2.3.0](https://github.com/lambdasistemi/cardano-ledger-rdf/compare/v0.2.2.0...v0.2.3.0) (2026-05-27)

### Features

* **vocab:** import transactions.ttl + serve at /vocab/cardano (IRI still old) ([bd33594](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/bd335946cda439966bb50cd97267f6e05a648c96))
* **vocab:** re-host vocab IRI to cardano-ledger-rdf ([fcc4121](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/fcc4121cfe1dab2aa8825198cd99e077e34c382c))
* **emitter:** typed gov_action_id sub-block on votes (mirror TxOutRef pattern) ([2bab0dd](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/2bab0dd5f4a41452b0f8119cc8283c476aa39652))
* **emitter:** typed proposal_procedure shell (deposit + return_address + anchor) ([69836d0](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/69836d08d89f64cfe569254c26631dc7e0922dae))
* **emitter:** typed TreasuryWithdrawals body (recipient + lovelace + guard policy) ([67da0a1](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/67da0a1cf43c38b4cd0445d14ac1ba51779f4161))
* **emitter:** tx-graph lattice-mode --in-dir + --out FILE (single merged Turtle) ([e9b7a95](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/e9b7a9525564a3dc5846c96b735e18698940c73b))

### Bug Fixes

* **ci:** release-planner back to ubuntu-latest ([777f494](https://github.com/lambdasistemi/cardano-ledger-rdf/commit/777f49464f18284d7a53e439fac380a5d015d2d9))

## [0.2.2.0](https://github.com/lambdasistemi/cardano-ledger-rdf/releases/tag/v0.2.2.0) (2026-05-26)

### Features

* Initial `cardano-ledger-rdf` repository extraction from the graph/RDF surface of `cardano-tx-tools`.
* Ship the RDF pipeline executables: `tx-fetch`, `tx-graph`, and `tx-view`.
* Keep `tx-graph` as a pure local transformation over operator rules plus transaction CBOR lattices.
* Keep `tx-view` as the packaged projection layer over generated Turtle graphs.
* Port Linux AppImage/DEB/RPM and Darwin/Homebrew release automation for the three RDF executables only.

### Removed

* Do not ship `tx-inspect`, `tx-diff`, `tx-sign`, `tx-validate`, or `cardano-tx-generator` from this repository.
* Drop the node-to-client resolver sublibrary and generator sublibrary from this package.

### Notes

`cardano-tx-tools` remains the downstream home for generic transaction
applications. It may depend on this repository when those applications
consume `tx-graph` output.
