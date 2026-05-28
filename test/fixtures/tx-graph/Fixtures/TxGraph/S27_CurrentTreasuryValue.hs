{- |
Module      : Fixtures.TxGraph.S27_CurrentTreasuryValue
Description : Conway current treasury value body-field fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S27_CurrentTreasuryValue (
    storyId,
    tx,
    shape,
) where

import Lens.Micro ((&), (.~))

import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (
    currentTreasuryValueTxBodyL,
    mkBasicTxBody,
 )
import Cardano.Ledger.BaseTypes (StrictMaybe (SJust))
import Cardano.Ledger.Coin (Coin (..))

import Cardano.Tx.Ledger (ConwayTx)
import Fixtures.TxGraph.Helpers (ExpectedShape, StoryId (..), baseShape)

storyId :: StoryId
storyId = StoryId "27-current-treasury-value"

tx :: ConwayTx
tx =
    mkBasicTx mkBasicTxBody
        & bodyTxL . currentTreasuryValueTxBodyL
            .~ SJust (Coin 90_000_000_000_000_000)

shape :: ExpectedShape
shape = baseShape
