{- |
Module      : Fixtures.TxGraph.S29_GovActionParameterChange
Description : Conway parameter-change governance action fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S29_GovActionParameterChange (
    storyId,
    tx,
    shape,
) where

import Data.Maybe (fromJust)
import Data.OSet.Strict qualified as OSet

import Lens.Micro ((&), (.~))

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Ledger.Api.PParams (
    PParamsUpdate,
    emptyPParamsUpdate,
    ppuMaxTxSizeL,
    ppuTxFeeFixedL,
 )
import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (mkBasicTxBody, proposalProceduresTxBodyL)
import Cardano.Ledger.BaseTypes (StrictMaybe (SJust, SNothing), textToUrl)
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.Governance (
    Anchor (..),
    GovAction (ParameterChange),
    ProposalProcedure (..),
 )
import Cardano.Ledger.Hashes (
    ADDRHASH,
    HASH,
    Hash,
    ScriptHash (..),
    unsafeMakeSafeHash,
 )

import Cardano.Tx.Decode (ConwayTx)
import Fixtures.TxGraph.Helpers (
    ExpectedShape (..),
    StoryId (..),
    baseShape,
    stubRewardAccount,
 )

storyId :: StoryId
storyId = StoryId "29-govaction-parameter-change"

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
        (stubRewardAccount 27)
        (ParameterChange SNothing pparamsUpdate (SJust guardPolicy))
        anchor

pparamsUpdate :: PParamsUpdate ConwayEra
pparamsUpdate =
    emptyPParamsUpdate
        & ppuTxFeeFixedL .~ SJust (Coin 44)
        & ppuMaxTxSizeL .~ SJust 16_384

guardPolicy :: ScriptHash
guardPolicy = ScriptHash (hash28 'a')

anchor :: Anchor
anchor =
    Anchor
        (fromJust (textToUrl 128 "https://example.invalid/parameter-change"))
        (unsafeMakeSafeHash (hash32 '1'))

hash28 :: Char -> Hash ADDRHASH a
hash28 c = fromJust (hashFromStringAsHex (replicate 56 c))

hash32 :: Char -> Hash HASH a
hash32 c = fromJust (hashFromStringAsHex (replicate 64 c))
