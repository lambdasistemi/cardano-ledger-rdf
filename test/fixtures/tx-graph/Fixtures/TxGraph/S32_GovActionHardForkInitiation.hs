{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

{- |
Module      : Fixtures.TxGraph.S32_GovActionHardForkInitiation
Description : Conway hard-fork-initiation governance action fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S32_GovActionHardForkInitiation (
    storyId,
    tx,
    shape,
) where

import Data.Maybe (fromJust)
import Data.OSet.Strict qualified as OSet

import Lens.Micro ((&), (.~))

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (mkBasicTxBody, proposalProceduresTxBodyL)
import Cardano.Ledger.BaseTypes (ProtVer (..), StrictMaybe (SJust), textToUrl)
import Cardano.Ledger.Binary (natVersion)
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.Governance (
    Anchor (..),
    GovAction (HardForkInitiation),
    GovActionId (..),
    GovActionIx (..),
    GovActionPurpose (..),
    GovPurposeId (..),
    ProposalProcedure (..),
 )
import Cardano.Ledger.Hashes (
    HASH,
    Hash,
    unsafeMakeSafeHash,
 )
import Cardano.Ledger.TxIn (TxId (..))

import Cardano.Tx.Decode (ConwayTx)
import Fixtures.TxGraph.Helpers (
    ExpectedShape (..),
    StoryId (..),
    baseShape,
    stubRewardAccount,
 )

storyId :: StoryId
storyId = StoryId "32-govaction-hard-fork-initiation"

tx :: ConwayTx
tx =
    mkBasicTx mkBasicTxBody
        & bodyTxL . proposalProceduresTxBodyL .~ OSet.fromList [proposal]

shape :: ExpectedShape
shape = baseShape{esProposals = 1}

proposal :: ProposalProcedure ConwayEra
proposal =
    ProposalProcedure
        (Coin 100_000_000_000)
        (stubRewardAccount 30)
        (HardForkInitiation (SJust priorAction) (ProtVer (natVersion @11) 0))
        anchor

priorAction :: GovPurposeId 'HardForkPurpose
priorAction =
    GovPurposeId $
        GovActionId
            (TxId (unsafeMakeSafeHash (hash32 '7')))
            (GovActionIx 9)

anchor :: Anchor
anchor =
    Anchor
        (fromJust (textToUrl 128 "https://example.invalid/hard-fork-initiation"))
        (unsafeMakeSafeHash (hash32 '8'))

hash32 :: Char -> Hash HASH a
hash32 c = fromJust (hashFromStringAsHex (replicate 64 c))
