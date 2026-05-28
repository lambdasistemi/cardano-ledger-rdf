# Spec — Typed `native_script` tree walker (closes #13)

Closes [#13](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/13).

## Why

Native scripts are currently visible only as script hash and CBOR bytes.
That makes multisig and timelock structure opaque to RDF queries, so a
SPARQL author cannot ask which scripts share a signer, which scripts are
threshold multisigs, or which transactions carry the same timelock shape
without decoding CBOR outside the graph.

## P1 User Story

As a SPARQL author analysing a transaction lattice, I want every native
script to emit a recursive typed tree, so I can query signer and threshold
structure directly in RDF and join script hashes back to reference scripts
and witness scripts.

## Functional Requirements

- **FR-1 — Recursive typed shape.** Every native-script root MUST be a
  `cardano:NativeScript` node with one constructor-specific class:
  `cardano:ScriptPubkey`, `cardano:ScriptAll`, `cardano:ScriptAny`,
  `cardano:ScriptNofK`, `cardano:InvalidBefore`, or
  `cardano:InvalidHereafter`.
- **FR-2 — Child tree.** `ScriptAll`, `ScriptAny`, and `ScriptNofK` MUST
  link to child native-script nodes with `cardano:hasChild`. Child bnodes
  MUST be derived from the parent bnode plus a one-based `_cN` suffix.
- **FR-3 — Signer leaves.** `ScriptPubkey` leaves MUST link
  `cardano:requiresSigner` to the same `cardano:Identifier` bnode family
  used for payment-key hashes elsewhere in the emitter.
- **FR-4 — Threshold and timelock leaves.** `ScriptNofK` MUST carry
  `cardano:requiredCount`. `InvalidBefore` and `InvalidHereafter` MUST
  carry `cardano:hasSlot`.
- **FR-5 — Hash join retained.** Root native-script nodes MUST retain
  `cardano:hasHash` so scripts can join to hash references and deduplicate
  across reference-script and witness-script surfaces.
- **FR-6 — Raw bytes dropped for typed native scripts.** Native scripts that
  decode to the six Conway constructors MUST NOT emit `cardano:hasRawBytes`
  on the native-script node. Plutus and other opaque fallback surfaces keep
  their existing raw-byte behavior.
- **FR-7 — Shared walker.** Output reference scripts and witness-set scripts
  MUST use one shared native-script walker implementation.
- **FR-8 — Fixture coverage.** At least two tx-graph fixtures MUST cover
  nested multisig/threshold shape and timelock leaves. Any existing fixture
  containing native scripts MUST have its golden regenerated.
- **FR-9 — Vocabulary traceability.** Every new `cardano:` term emitted by
  the walker MUST be registered in `Vocab.hs`, declared in
  `vocab/cardano/transactions.ttl`, and present in the canonical vocab test
  fixture used by `VocabTraceabilitySpec`.

## Success Criteria

- New fixture goldens contain recursive native-script trees for nested
  multisig/threshold and timelock cases.
- Existing native-script fixture goldens replace `hasRawBytes` on native
  scripts with the typed tree while preserving `hasHash`.
- `nix develop -c just unit` exits 0.
- `nix build .#checks.x86_64-linux.{build,unit,lint,vocab-validate,vocab-owl-smoke}` exits 0.
- `./gate.sh origin/main..HEAD` exits 0.

## Out Of Scope

- Deleting migrated `cardano-tx-tools` source.
- Changing Plutus-script emission beyond preserving the existing
  `PlutusScript + hasHash + hasRawBytes + hasVersion` shape.
