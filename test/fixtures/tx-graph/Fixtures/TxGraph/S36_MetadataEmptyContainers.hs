{- |
Module      : Fixtures.TxGraph.S36_MetadataEmptyContainers
Description : Fixture 36 — zero-arity metadata containers (polish edge).
License     : Apache-2.0

Spec 062 polish: faithfulness at the arity-0 boundary. An empty
list ('Metadatum.List' @[]@) must surface as a @cardano:MetaList@
with __zero__ @cardano:hasElement@ edges, and an empty map
('Metadatum.Map' @[]@) as a @cardano:MetaMap@ with __zero__
@cardano:hasEntry@ edges — the decode neither invents an element
nor drops the typed node. Label 3 nests an empty list inside a
single-entry map to pin the recursive empty-container case.

The "auxiliary data with scripts but an empty top-level metadata
map" edge from the contract is not constructible through the pure
'Cardano.Tx.Build' DSL (auxiliary scripts are attached to the
witness set, not the auxiliary-data tuple), so the zero-edge
behaviour is exercised here at the value level instead.
-}
module Fixtures.TxGraph.S36_MetadataEmptyContainers (
    storyId,
    tx,
    shape,
) where

import Cardano.Ledger.Metadata (Metadatum (I, List, Map))
import Cardano.Tx.Build (output, setMetadata, spend)
import Cardano.Tx.Decode (ConwayTx)

import Fixtures.TxGraph.Helpers (
    ExpectedShape (..),
    StoryId (..),
    TxBuilder (..),
    baseShape,
    mkTx,
    stubTxIn,
    stubTxOut,
 )

-- | Story slug — kebab directory name under @test/fixtures/tx-graph/@.
storyId :: StoryId
storyId = StoryId "36-metadata-empty-containers"

{- | Conway tx whose metadata carries an empty list, an empty map, and
a map holding an empty list.
-}
tx :: ConwayTx
tx = mkTx . TxBuilder $ do
    _ <- spend (stubTxIn 36)
    _ <- output (stubTxOut 42_000_000)
    setMetadata 1 (List [])
    setMetadata 2 (Map [])
    setMetadata 3 (Map [(I 0, List [])])
    pure ()

-- | Expected structural shape.
shape :: ExpectedShape
shape = baseShape{esInputs = 1, esOutputs = 1}
