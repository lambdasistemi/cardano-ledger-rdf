{- |
Module      : Fixtures.TxGraph.S24_CertDRepAnchors
Description : Conway DRep certificate fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S24_CertDRepAnchors (
    storyId,
    tx,
    shape,
) where

import Data.Maybe (fromJust)
import Data.Sequence.Strict qualified as StrictSeq
import Data.Text qualified as Text

import Lens.Micro ((&), (.~))

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (certsTxBodyL, mkBasicTxBody)
import Cardano.Ledger.BaseTypes (StrictMaybe (SJust), textToUrl)
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.Governance (Anchor (..))
import Cardano.Ledger.Conway.TxCert (
    pattern RegDRepTxCert,
    pattern UnRegDRepTxCert,
    pattern UpdateDRepTxCert,
 )
import Cardano.Ledger.Core (TxCert)
import Cardano.Ledger.Credential (Credential (KeyHashObj))
import Cardano.Ledger.Hashes (
    ADDRHASH,
    HASH,
    Hash,
    KeyHash (..),
    unsafeMakeSafeHash,
 )
import Cardano.Ledger.Keys (KeyRole (..))

import Cardano.Tx.Ledger (ConwayTx)
import Fixtures.TxGraph.Helpers (ExpectedShape (..), StoryId (..), baseShape)

storyId :: StoryId
storyId = StoryId "24-cert-drep-anchors"

tx :: ConwayTx
tx =
    mkBasicTx mkBasicTxBody
        & bodyTxL . certsTxBodyL .~ StrictSeq.fromList certs

shape :: ExpectedShape
shape = baseShape{esCertificates = length certs}

certs :: [TxCert ConwayEra]
certs =
    [ RegDRepTxCert drepCred (Coin 500_000_000) (SJust anchor1)
    , UnRegDRepTxCert drepCred (Coin 500_000_000)
    , UpdateDRepTxCert drepCred (SJust anchor2)
    ]

drepCred :: Credential DRepRole
drepCred = KeyHashObj (KeyHash (hash28 '4'))

anchor1 :: Anchor
anchor1 = anchor "https://example.invalid/drep-registration" 'a'

anchor2 :: Anchor
anchor2 = anchor "https://example.invalid/drep-update" 'b'

anchor :: String -> Char -> Anchor
anchor url c =
    Anchor
        (fromJust (textToUrl 128 (Text.pack url)))
        (unsafeMakeSafeHash (hash32 c))

hash28 :: Char -> Hash ADDRHASH a
hash28 c = fromJust (hashFromStringAsHex (replicate 56 c))

hash32 :: Char -> Hash HASH a
hash32 c = fromJust (hashFromStringAsHex (replicate 64 c))
