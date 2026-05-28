# Spec - IRI promotion for cross-response composability

Issue: [#56](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/56)
Status: in progress

## Why

Single transaction responses currently use deterministic blank-node labels for
chain-wide identities such as transaction ids, output positions, and hash or
credential identifiers. That works only inside one RDF parse scope. When two
Turtle responses are parsed independently, equal blank-node labels do not denote
the same RDF node, so cross-response joins break.

This feature promotes content-addressed graph nodes to Cardano URNs and keeps
only emit-local structure as blank nodes. The remaining blank nodes are scoped
deterministically so concatenating independently emitted Turtle documents cannot
collide on structural labels.

## Functional Requirements

- **FR-1 - Transaction subject IRI.** The transaction subject MUST be emitted as `urn:cardano:tx:<txid_hex>` instead of `_:tx`.
- **FR-2 - UTxO output IRI.** Each body output subject and each `cardano:hasOutput` object MUST be emitted as `urn:cardano:utxo:<txid_hex>:<zero_based_index>`.
- **FR-3 - Identifier IRI.** Hash and credential identifier nodes MUST be emitted as `urn:cardano:id:<LeafType>:<identifier>` IRIs. The `LeafType` segment keeps the existing camel-case leaf type text.
- **FR-4 - Universal blank-node prefix.** Every remaining per-transaction structural blank node MUST carry the first eight hex characters of the transaction id as a prefix. Address-decomposition blank nodes MUST instead be anchored by credential hex, not the transaction id.
- **FR-5 - Cat-merge composability.** Concatenating two transaction Turtle responses where one spends an output from the other MUST support a SPARQL join from the spending input to the producing output and return the spent output lovelace exactly once.

## Out Of Scope

- Operator-declared entity subjects stay in the fixture-local namespace or as
  operator overlay nodes. The rules file format is unchanged.
- `cardano:hasReferencedTxId` and `cardano:hasIndex` scalar semantics are not
  changed. Only resource identity nodes move from blank nodes to IRIs.

## Success Criteria

- Tx, UTxO, and identifier resources appear as URNs in regenerated Turtle.
- Structural blank-node labels are collision-resistant across single-response
  Turtle documents.
- `CatMergeCompositionSpec` passes with an `arq` SPARQL query over concatenated
  Turtle.
- Unit, Nix checks, MkDocs strict build, and `gate.sh origin/main..HEAD` pass.
