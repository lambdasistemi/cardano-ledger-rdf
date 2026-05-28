# Plan — Typed `native_script` tree walker

## Tech Stack

- Haskell `cardano-ledger-rdf` library
- `Cardano.Ledger.Allegra.Scripts` pattern synonyms for native-script
  variants
- `src/Cardano/Tx/Graph/Emit/NativeScript.hs` as the shared walker
- `src/Cardano/Tx/Graph/Emit/Project.hs` for output reference scripts
- `src/Cardano/Tx/Graph/Emit/Witness.hs` for witness-set scripts
- `src/Cardano/Tx/Graph/Emit/Vocab.hs` and
  `vocab/cardano/transactions.ttl` for vocabulary
- Hspec and tx-graph Turtle goldens

## Slice Boundaries

One bisect-safe slice. The behavior is one vertical RDF-shape change:
native scripts move from opaque raw bytes to a recursive typed tree at both
existing emit sites. Keeping this in a single commit prevents a temporary
state where one surface is typed and the other is still opaque.

## Shared Walker Decision

Add `Cardano.Tx.Graph.Emit.NativeScript` as a private library module. The
module takes the lookup table and identifier resolver as arguments, so it can
emit signer and hash identifier nodes without importing `Project` and creating
a cycle. `Project` and `Witness` each keep their Plutus handling and delegate
only `NativeScript native` to the shared walker.

## Golden-Regeneration Plan

1. Add focused tests for recursive variants on output reference scripts and
   witness scripts; run them before implementation to observe RED.
2. Implement the shared walker and rewire both emit sites.
3. Add two fixture modules and directories:
   `18-native-script-nested` and `19-native-script-timelock`.
4. Regenerate tx-graph goldens with `EMIT_GOLDEN_REGEN=1`.
5. Inspect the native-script golden diffs to confirm only native-script
   blocks changed from raw bytes to typed structure, with hash joins intact.
6. Run the requested unit, Nix checks, and gate commands.

## Risks

- **Bnode stability:** child names must append `_cN` to the parent bnode name
  before serializer tx scoping, or goldens will churn unnecessarily.
- **Identifier joins:** signer leaves must resolve through the same
  `PaymentKey` identifier helper as required signers so SPARQL joins work.
- **Vocab drift:** new terms must be in `Vocab.hs`, public vocab Turtle, and
  the canonical vocab fixture or the traceability spec will fail.
