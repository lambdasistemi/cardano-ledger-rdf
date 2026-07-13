{- |
Module      : Fixtures.TxGraph.S37_VotingProcedure
Description : Conway voting-procedure identifier fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S37_VotingProcedure (
    storyId,
    tx,
    shape,
) where

import Data.Map.Strict qualified as Map
import Data.Maybe (fromJust)

import Lens.Micro ((&), (.~))

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (mkBasicTxBody, votingProceduresTxBodyL)
import Cardano.Ledger.BaseTypes (StrictMaybe (SNothing))
import Cardano.Ledger.Conway.Governance (
    GovActionId (..),
    GovActionIx (..),
    Vote (VoteYes),
    Voter (DRepVoter),
    VotingProcedure (..),
    VotingProcedures (..),
 )
import Cardano.Ledger.Credential (Credential (KeyHashObj))
import Cardano.Ledger.Hashes (
    ADDRHASH,
    HASH,
    Hash,
    KeyHash (..),
    unsafeMakeSafeHash,
 )
import Cardano.Ledger.Keys (KeyRole (DRepRole))
import Cardano.Ledger.TxIn (TxId (..))

import Cardano.Tx.Decode (ConwayTx)
import Fixtures.TxGraph.Helpers (ExpectedShape, StoryId (..), baseShape)

-- | Story slug — kebab directory name under @test/fixtures/tx-graph/@.
storyId :: StoryId
storyId = StoryId "37-voting-procedure"

-- | Conway transaction with one DRep-key voting procedure.
tx :: ConwayTx
tx =
    mkBasicTx mkBasicTxBody
        & bodyTxL . votingProceduresTxBodyL
            .~ VotingProcedures
                (Map.singleton voter (Map.singleton actionId procedure))

-- | Expected structural shape.
shape :: ExpectedShape
shape = baseShape

voter :: Voter
voter = DRepVoter (KeyHashObj drepKey)

drepKey :: KeyHash DRepRole
drepKey = KeyHash (hash28 'a')

actionId :: GovActionId
actionId =
    GovActionId
        (TxId (unsafeMakeSafeHash (hash32 'b')))
        (GovActionIx 0)

procedure :: VotingProcedure era
procedure = VotingProcedure VoteYes SNothing

hash28 :: Char -> Hash ADDRHASH a
hash28 c = fromJust (hashFromStringAsHex (replicate 56 c))

hash32 :: Char -> Hash HASH a
hash32 c = fromJust (hashFromStringAsHex (replicate 64 c))
