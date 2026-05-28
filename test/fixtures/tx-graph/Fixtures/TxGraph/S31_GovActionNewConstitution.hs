{-# LANGUAGE DataKinds #-}

{- |
Module      : Fixtures.TxGraph.S31_GovActionNewConstitution
Description : Conway new-constitution governance action fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S31_GovActionNewConstitution (
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
import Cardano.Ledger.BaseTypes (StrictMaybe (SJust), textToUrl)
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.Governance (
    Anchor (..),
    Constitution (..),
    GovAction (NewConstitution),
    GovActionId (..),
    GovActionIx (..),
    GovActionPurpose (..),
    GovPurposeId (..),
    ProposalProcedure (..),
 )
import Cardano.Ledger.Hashes (
    ADDRHASH,
    HASH,
    Hash,
    ScriptHash (..),
    unsafeMakeSafeHash,
 )
import Cardano.Ledger.TxIn (TxId (..))

import Cardano.Tx.Ledger (ConwayTx)
import Fixtures.TxGraph.Helpers (
    ExpectedShape (..),
    StoryId (..),
    baseShape,
    stubRewardAccount,
 )

storyId :: StoryId
storyId = StoryId "31-govaction-new-constitution"

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
        (stubRewardAccount 29)
        (NewConstitution (SJust priorAction) constitution)
        proposalAnchor

priorAction :: GovPurposeId 'ConstitutionPurpose
priorAction =
    GovPurposeId $
        GovActionId
            (TxId (unsafeMakeSafeHash (hash32 '4')))
            (GovActionIx 8)

constitution :: Constitution ConwayEra
constitution =
    Constitution constitutionDocAnchor (SJust guardrailScript)

proposalAnchor :: Anchor
proposalAnchor =
    Anchor
        (fromJust (textToUrl 128 "https://example.invalid/constitution-proposal"))
        (unsafeMakeSafeHash (hash32 '5'))

constitutionDocAnchor :: Anchor
constitutionDocAnchor =
    Anchor
        (fromJust (textToUrl 128 "https://example.invalid/constitution"))
        (unsafeMakeSafeHash (hash32 '6'))

guardrailScript :: ScriptHash
guardrailScript = ScriptHash (hash28 'd')

hash28 :: Char -> Hash ADDRHASH a
hash28 c = fromJust (hashFromStringAsHex (replicate 56 c))

hash32 :: Char -> Hash HASH a
hash32 c = fromJust (hashFromStringAsHex (replicate 64 c))
