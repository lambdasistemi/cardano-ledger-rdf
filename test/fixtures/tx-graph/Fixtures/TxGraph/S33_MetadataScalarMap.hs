{- |
Module      : Fixtures.TxGraph.S33_MetadataScalarMap
Description : Fixture 33 — scalar + nested-map transaction metadata (US1).
License     : Apache-2.0

Spec 062 / User Story 1: metadata contents become reachable as
triples. Three top-level labels exercise the integer leaf
('Metadatum.I' → @cardano:MetaInt@), the text leaf
('Metadatum.S' → @cardano:MetaText@), and a nested map
('Metadatum.Map' → @cardano:MetaMap@ with @cardano:hasEntry@,
string keys, and a scalar value inside). Labels are deliberately
out of insertion order (7, 674, 61284) so the golden pins the
ascending-label emission order (FR-007).
-}
module Fixtures.TxGraph.S33_MetadataScalarMap (
    storyId,
    tx,
    shape,
) where

import Cardano.Ledger.Metadata (Metadatum (I, Map, S))
import Cardano.Tx.Build (output, setMetadata, spend)
import Cardano.Tx.Ledger (ConwayTx)

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
storyId = StoryId "33-metadata-scalar-map"

{- | Conway tx whose auxiliary data carries an integer, a text, and a
nested-map metadata label.
-}
tx :: ConwayTx
tx = mkTx . TxBuilder $ do
    _ <- spend (stubTxIn 33)
    _ <- output (stubTxOut 42_000_000)
    setMetadata 7 (I 42)
    setMetadata 674 (S "hello")
    setMetadata
        61284
        ( Map
            [
                ( S "body"
                , Map
                    [ (S "event", S "disburse")
                    , (S "count", I 3)
                    ]
                )
            ]
        )
    pure ()

-- | Expected structural shape.
shape :: ExpectedShape
shape = baseShape{esInputs = 1, esOutputs = 1}
