{- |
Module      : Fixtures.TxGraph.S28_Donation
Description : Conway treasury donation body-field fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S28_Donation (
    storyId,
    tx,
    shape,
) where

import Lens.Micro ((&), (.~))

import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (mkBasicTxBody, treasuryDonationTxBodyL)
import Cardano.Ledger.Coin (Coin (..))

import Cardano.Tx.Decode (ConwayTx)
import Fixtures.TxGraph.Helpers (ExpectedShape, StoryId (..), baseShape)

storyId :: StoryId
storyId = StoryId "28-donation"

tx :: ConwayTx
tx =
    mkBasicTx mkBasicTxBody
        & bodyTxL . treasuryDonationTxBodyL .~ Coin 1_000_000

shape :: ExpectedShape
shape = baseShape
