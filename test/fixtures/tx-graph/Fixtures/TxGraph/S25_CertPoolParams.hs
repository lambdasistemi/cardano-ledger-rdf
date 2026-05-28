{- |
Module      : Fixtures.TxGraph.S25_CertPoolParams
Description : Conway pool certificate fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S25_CertPoolParams (
    storyId,
    tx,
    shape,
) where

import Data.ByteString qualified as BS
import Data.ByteString.Short qualified as SBS
import Data.Maybe (fromJust)
import Data.MemPack.Buffer (byteArrayFromShortByteString)
import Data.Ratio ((%))
import Data.Sequence.Strict qualified as StrictSeq
import Data.Set qualified as Set

import Lens.Micro ((&), (.~))

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (certsTxBodyL, mkBasicTxBody)
import Cardano.Ledger.Api.Tx.Cert (
    pattern RegPoolTxCert,
    pattern RetirePoolTxCert,
 )
import Cardano.Ledger.BaseTypes (
    BoundedRational (boundRational),
    EpochNo (..),
    Port (..),
    StrictMaybe (SJust, SNothing),
    UnitInterval,
    textToDns,
    textToUrl,
 )
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Core (TxCert)
import Cardano.Ledger.Hashes (
    ADDRHASH,
    HASH,
    Hash,
    KeyHash (..),
    VRFVerKeyHash (..),
 )
import Cardano.Ledger.Keys (KeyRole (..), KeyRoleVRF (..))
import Cardano.Ledger.State (
    PoolMetadata (..),
    StakePoolParams (..),
    StakePoolRelay (..),
 )

import Cardano.Tx.Ledger (ConwayTx)
import Fixtures.TxGraph.Helpers (
    ExpectedShape (..),
    StoryId (..),
    baseShape,
    stubRewardAccount,
 )

storyId :: StoryId
storyId = StoryId "25-cert-pool-params"

tx :: ConwayTx
tx =
    mkBasicTx mkBasicTxBody
        & bodyTxL . certsTxBodyL .~ StrictSeq.fromList certs

shape :: ExpectedShape
shape = baseShape{esCertificates = length certs}

certs :: [TxCert ConwayEra]
certs =
    [ RegPoolTxCert poolParams
    , RetirePoolTxCert operator (EpochNo 580)
    ]

poolParams :: StakePoolParams
poolParams =
    StakePoolParams
        { sppId = operator
        , sppVrf = vrfHash
        , sppPledge = Coin 1_000_000_000_000
        , sppCost = Coin 340_000_000
        , sppMargin = margin
        , sppAccountAddress = stubRewardAccount 25
        , sppOwners = Set.fromList [owner1, owner2]
        , sppRelays =
            StrictSeq.fromList
                [ SingleHostAddr (SJust (Port 3001)) SNothing SNothing
                , SingleHostName
                    (SJust (Port 3002))
                    (fromJust (textToDns 128 "relay.example.invalid"))
                , MultiHostName
                    (fromJust (textToDns 128 "_cardano._tcp.example.invalid"))
                ]
        , sppMetadata =
            SJust $
                PoolMetadata
                    (fromJust (textToUrl 128 "https://example.invalid/pool.json"))
                    (byteArrayFromShortByteString (SBS.toShort (BS.replicate 32 0x55)))
        }

operator :: KeyHash StakePool
operator = KeyHash (hash28 '5')

owner1 :: KeyHash Staking
owner1 = KeyHash (hash28 '6')

owner2 :: KeyHash Staking
owner2 = KeyHash (hash28 '7')

vrfHash :: VRFVerKeyHash StakePoolVRF
vrfHash = VRFVerKeyHash (hash32 '8')

margin :: UnitInterval
margin = fromJust (boundRational (1 % 40))

hash28 :: Char -> Hash ADDRHASH a
hash28 c = fromJust (hashFromStringAsHex (replicate 56 c))

hash32 :: Char -> Hash HASH a
hash32 c = fromJust (hashFromStringAsHex (replicate 64 c))
