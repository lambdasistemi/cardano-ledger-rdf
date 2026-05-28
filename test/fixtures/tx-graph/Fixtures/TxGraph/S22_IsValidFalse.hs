{- |
Module      : Fixtures.TxGraph.S22_IsValidFalse
Description : Fixture 20 — transaction with IsValid False.
License     : Apache-2.0

Small Conway transaction with the phase-2 validity flag forced to false.
This is not intended to be ledger-valid; it pins faithful RDF emission of the
transaction tuple's @isValid@ slot.
-}
module Fixtures.TxGraph.S22_IsValidFalse (
    storyId,
    tx,
    shape,
) where

import Lens.Micro ((&), (.~))

import Cardano.Ledger.Api.Tx (IsValid (..), isValidTxL)
import Cardano.Tx.Build (output, spend)
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
storyId = StoryId "22-isvalid-false"

-- | Conway tx with @isValidTxL@ forced to @IsValid False@.
tx :: ConwayTx
tx =
    ( mkTx . TxBuilder $ do
        _ <- spend (stubTxIn 20)
        _ <- output (stubTxOut 21_000_000)
        pure ()
    )
        & isValidTxL .~ IsValid False

-- | Expected structural shape.
shape :: ExpectedShape
shape = baseShape{esInputs = 1, esOutputs = 1}
