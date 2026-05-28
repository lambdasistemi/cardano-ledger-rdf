{- |
Module      : Fixtures.TxGraph.S21_AuxiliaryData
Description : Fixture 19 — transaction auxiliary data body.
License     : Apache-2.0

Small metadata-bearing Conway transaction for issue #17. The metadata is
enough for the ledger builder to populate both the body-level
@auxDataHashTxBodyL@ and the transaction tuple's @auxDataTxL@ slot.
-}
module Fixtures.TxGraph.S21_AuxiliaryData (
    storyId,
    tx,
    shape,
) where

import Cardano.Ledger.Metadata (Metadatum (S))
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
storyId = StoryId "21-auxiliary-data"

-- | Conway tx with one metadata label in auxiliary data.
tx :: ConwayTx
tx = mkTx . TxBuilder $ do
    _ <- spend (stubTxIn 19)
    _ <- output (stubTxOut 42_000_000)
    setMetadata 674 (S "auxiliary-data-fixture")
    pure ()

-- | Expected structural shape.
shape :: ExpectedShape
shape = baseShape{esInputs = 1, esOutputs = 1}
