{- |
Module      : Fixtures.TxGraph.S19_NativeScriptTimelock
Description : Timelock native-script reference-script fixture.
License     : Apache-2.0

Synthetic tx-graph fixture for issue #13. The single output carries a
native reference script with invalid-before and invalid-hereafter leaves.
-}
module Fixtures.TxGraph.S19_NativeScriptTimelock (
    tx,
) where

import Data.Maybe (fromJust)
import Data.Sequence.Strict qualified as StrictSeq

import Lens.Micro ((&), (.~))

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Ledger.Address (Addr (..))
import Cardano.Ledger.Allegra.Scripts (
    pattern RequireTimeExpire,
    pattern RequireTimeStart,
 )
import Cardano.Ledger.Alonzo.Scripts (AlonzoScript (NativeScript))
import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (mkBasicTxBody, outputsTxBodyL)
import Cardano.Ledger.Api.Tx.Out (mkBasicTxOut, referenceScriptTxOutL)
import Cardano.Ledger.BaseTypes (
    Network (Testnet),
    SlotNo (..),
    StrictMaybe (SJust),
 )
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Core (Script)
import Cardano.Ledger.Credential (
    Credential (KeyHashObj),
    StakeReference (StakeRefNull),
 )
import Cardano.Ledger.Hashes (KeyHash (..))
import Cardano.Ledger.Keys (KeyRole (Payment))
import Cardano.Ledger.Mary.Value (MaryValue (..), MultiAsset (..))
import Cardano.Ledger.Shelley.Scripts (pattern RequireAllOf)

import Cardano.Tx.Decode (ConwayTx)

tx :: ConwayTx
tx =
    mkBasicTx mkBasicTxBody
        & bodyTxL . outputsTxBodyL
            .~ StrictSeq.fromList
                [ mkBasicTxOut
                    stubAddr
                    (MaryValue (Coin 3_000_000) (MultiAsset mempty))
                    & referenceScriptTxOutL .~ SJust timelockScript
                ]

timelockScript :: Script ConwayEra
timelockScript =
    NativeScript $
        RequireAllOf $
            StrictSeq.fromList
                [ RequireTimeStart (SlotNo 145_000_000)
                , RequireTimeExpire (SlotNo 146_000_000)
                ]

stubAddr :: Addr
stubAddr =
    Addr
        Testnet
        (KeyHashObj (KeyHash (fromJust (hashFromStringAsHex (replicate 56 '6'))) :: KeyHash Payment))
        StakeRefNull
