{- |
Module      : Fixtures.TxGraph.S26_CertCommittee
Description : Conway committee certificate fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S26_CertCommittee (
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
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.Governance (Anchor (..))
import Cardano.Ledger.Conway.TxCert (
    pattern AuthCommitteeHotKeyTxCert,
    pattern ResignCommitteeColdTxCert,
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

import Cardano.Tx.Decode (ConwayTx)
import Fixtures.TxGraph.Helpers (ExpectedShape (..), StoryId (..), baseShape)

storyId :: StoryId
storyId = StoryId "26-cert-committee"

tx :: ConwayTx
tx =
    mkBasicTx mkBasicTxBody
        & bodyTxL . certsTxBodyL .~ StrictSeq.fromList certs

shape :: ExpectedShape
shape = baseShape{esCertificates = length certs}

certs :: [TxCert ConwayEra]
certs =
    [ AuthCommitteeHotKeyTxCert coldCred hotCred
    , ResignCommitteeColdTxCert coldCred (SJust anchor)
    ]

coldCred :: Credential ColdCommitteeRole
coldCred = KeyHashObj (KeyHash (hash28 '9'))

hotCred :: Credential HotCommitteeRole
hotCred = KeyHashObj (KeyHash (hash28 'a'))

anchor :: Anchor
anchor =
    Anchor
        (fromJust (textToUrl 128 (Text.pack "https://example.invalid/committee-resign")))
        (unsafeMakeSafeHash (hash32 'c'))

hash28 :: Char -> Hash ADDRHASH a
hash28 c = fromJust (hashFromStringAsHex (replicate 56 c))

hash32 :: Char -> Hash HASH a
hash32 c = fromJust (hashFromStringAsHex (replicate 64 c))
