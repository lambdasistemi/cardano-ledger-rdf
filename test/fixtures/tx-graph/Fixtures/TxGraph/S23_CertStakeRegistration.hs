{- |
Module      : Fixtures.TxGraph.S23_CertStakeRegistration
Description : Conway stake-credential certificate fixture.
License     : Apache-2.0
-}
module Fixtures.TxGraph.S23_CertStakeRegistration (
    storyId,
    tx,
    shape,
) where

import Data.Maybe (fromJust)
import Data.Sequence.Strict qualified as StrictSeq

import Lens.Micro ((&), (.~))

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (certsTxBodyL, mkBasicTxBody)
import Cardano.Ledger.Api.Tx.Cert (Delegatee (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.TxCert (
    pattern RegDepositDelegTxCert,
    pattern RegDepositTxCert,
    pattern UnRegDepositTxCert,
 )
import Cardano.Ledger.Core (TxCert)
import Cardano.Ledger.Credential (Credential (KeyHashObj))
import Cardano.Ledger.DRep (DRep (DRepKeyHash))
import Cardano.Ledger.Hashes (ADDRHASH, Hash, KeyHash (..))
import Cardano.Ledger.Keys (KeyRole (..))

import Cardano.Tx.Ledger (ConwayTx)
import Fixtures.TxGraph.Helpers (ExpectedShape (..), StoryId (..), baseShape)

storyId :: StoryId
storyId = StoryId "23-cert-stake-registration"

tx :: ConwayTx
tx =
    mkBasicTx mkBasicTxBody
        & bodyTxL . certsTxBodyL .~ StrictSeq.fromList certs

shape :: ExpectedShape
shape = baseShape{esCertificates = length certs}

certs :: [TxCert ConwayEra]
certs =
    [ RegDepositTxCert stakeCred (Coin 2_000_000)
    , UnRegDepositTxCert stakeCred (Coin 2_000_000)
    , RegDepositDelegTxCert
        stakeCred
        (DelegStake poolKey)
        (Coin 2_000_000)
    , RegDepositDelegTxCert
        stakeCred
        (DelegVote (DRepKeyHash drepKey))
        (Coin 2_000_000)
    , RegDepositDelegTxCert
        stakeCred
        (DelegStakeVote poolKey (DRepKeyHash drepKey))
        (Coin 2_000_000)
    ]

stakeCred :: Credential Staking
stakeCred = KeyHashObj stakeKey

stakeKey :: KeyHash Staking
stakeKey = KeyHash (hash28 '1')

poolKey :: KeyHash StakePool
poolKey = KeyHash (hash28 '2')

drepKey :: KeyHash DRepRole
drepKey = KeyHash (hash28 '3')

hash28 :: Char -> Hash ADDRHASH a
hash28 c = fromJust (hashFromStringAsHex (replicate 56 c))
