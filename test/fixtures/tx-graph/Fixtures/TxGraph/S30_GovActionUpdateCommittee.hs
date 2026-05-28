{-# LANGUAGE DataKinds #-}

{- |
Module      : Fixtures.TxGraph.S30_GovActionUpdateCommittee
Description : Conway update-committee governance action fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S30_GovActionUpdateCommittee (
    storyId,
    tx,
    shape,
) where

import Data.Map.Strict qualified as Map
import Data.Maybe (fromJust)
import Data.OSet.Strict qualified as OSet
import Data.Ratio ((%))
import Data.Set qualified as Set

import Lens.Micro ((&), (.~))

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (mkBasicTxBody, proposalProceduresTxBodyL)
import Cardano.Ledger.BaseTypes (
    BoundedRational (boundRational),
    EpochNo (..),
    StrictMaybe (SJust),
    UnitInterval,
    textToUrl,
 )
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.Governance (
    Anchor (..),
    GovAction (UpdateCommittee),
    GovActionId (..),
    GovActionIx (..),
    GovActionPurpose (..),
    GovPurposeId (..),
    ProposalProcedure (..),
 )
import Cardano.Ledger.Credential (Credential (KeyHashObj))
import Cardano.Ledger.Hashes (
    ADDRHASH,
    HASH,
    Hash,
    KeyHash (..),
    unsafeMakeSafeHash,
 )
import Cardano.Ledger.Keys (KeyRole (ColdCommitteeRole))
import Cardano.Ledger.TxIn (TxId (..))

import Cardano.Tx.Ledger (ConwayTx)
import Fixtures.TxGraph.Helpers (
    ExpectedShape (..),
    StoryId (..),
    baseShape,
    stubRewardAccount,
 )

storyId :: StoryId
storyId = StoryId "30-govaction-update-committee"

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
        (stubRewardAccount 28)
        ( UpdateCommittee
            (SJust priorAction)
            (Set.singleton oldMember)
            (Map.singleton newMember (EpochNo 1234))
            quorum
        )
        anchor

priorAction :: GovPurposeId 'CommitteePurpose
priorAction =
    GovPurposeId $
        GovActionId
            (TxId (unsafeMakeSafeHash (hash32 '2')))
            (GovActionIx 7)

oldMember :: Credential ColdCommitteeRole
oldMember = KeyHashObj (KeyHash (hash28 'b'))

newMember :: Credential ColdCommitteeRole
newMember = KeyHashObj (KeyHash (hash28 'c'))

quorum :: UnitInterval
quorum = fromJust (boundRational (2 % 3))

anchor :: Anchor
anchor =
    Anchor
        (fromJust (textToUrl 128 "https://example.invalid/update-committee"))
        (unsafeMakeSafeHash (hash32 '3'))

hash28 :: Char -> Hash ADDRHASH a
hash28 c = fromJust (hashFromStringAsHex (replicate 56 c))

hash32 :: Char -> Hash HASH a
hash32 c = fromJust (hashFromStringAsHex (replicate 64 c))
