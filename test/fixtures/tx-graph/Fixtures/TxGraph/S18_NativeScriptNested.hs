{- |
Module      : Fixtures.TxGraph.S18_NativeScriptNested
Description : Nested native-script reference-script fixture.
License     : Apache-2.0

Synthetic tx-graph fixture for issue #13. The single output carries a
native reference script shaped as ScriptAll(signers, ScriptNofK(...))
so the golden pins recursive child bnode naming and threshold emission.
-}
module Fixtures.TxGraph.S18_NativeScriptNested (
    tx,
) where

import Data.Maybe (fromJust)
import Data.Sequence.Strict qualified as StrictSeq

import Lens.Micro ((&), (.~))

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Ledger.Address (Addr (..))
import Cardano.Ledger.Alonzo.Scripts (AlonzoScript (NativeScript))
import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx)
import Cardano.Ledger.Api.Tx.Body (mkBasicTxBody, outputsTxBodyL)
import Cardano.Ledger.Api.Tx.Out (mkBasicTxOut, referenceScriptTxOutL)
import Cardano.Ledger.BaseTypes (Network (Testnet), StrictMaybe (SJust))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Core (Script)
import Cardano.Ledger.Credential (
    Credential (KeyHashObj),
    StakeReference (StakeRefNull),
 )
import Cardano.Ledger.Hashes (KeyHash (..))
import Cardano.Ledger.Keys (KeyRole (Payment, Witness))
import Cardano.Ledger.Mary.Value (MaryValue (..), MultiAsset (..))
import Cardano.Ledger.Shelley.Scripts (
    pattern RequireAllOf,
    pattern RequireAnyOf,
    pattern RequireMOf,
    pattern RequireSignature,
 )

import Cardano.Tx.Ledger (ConwayTx)

tx :: ConwayTx
tx =
    mkBasicTx mkBasicTxBody
        & bodyTxL . outputsTxBodyL
            .~ StrictSeq.fromList
                [ mkBasicTxOut
                    stubAddr
                    (MaryValue (Coin 2_000_000) (MultiAsset mempty))
                    & referenceScriptTxOutL .~ SJust nestedScript
                ]

nestedScript :: Script ConwayEra
nestedScript =
    NativeScript $
        RequireAllOf $
            StrictSeq.fromList
                [ RequireSignature (keyHash '1')
                , RequireMOf
                    2
                    ( StrictSeq.fromList
                        [ RequireSignature (keyHash '2')
                        , RequireSignature (keyHash '3')
                        , RequireAnyOf $
                            StrictSeq.fromList
                                [ RequireSignature (keyHash '4')
                                , RequireSignature (keyHash '5')
                                ]
                        ]
                    )
                ]

keyHash :: Char -> KeyHash Witness
keyHash c =
    KeyHash (fromJust (hashFromStringAsHex (replicate 56 c)))

stubAddr :: Addr
stubAddr =
    Addr
        Testnet
        (KeyHashObj paymentKeyHash)
        StakeRefNull

paymentKeyHash :: KeyHash Payment
paymentKeyHash =
    KeyHash (fromJust (hashFromStringAsHex (replicate 56 '0')))
