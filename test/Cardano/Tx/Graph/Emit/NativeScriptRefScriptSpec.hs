{- |
Module      : Cardano.Tx.Graph.Emit.NativeScriptRefScriptSpec
Description : Reference-script native-script typed tree shape.
License     : Apache-2.0

Asserts issue #13's native-script walker contract on reference
scripts: a Conway @TimelockScript@ emits a recursive typed tree
instead of opaque CBOR bytes, while retaining the root script-hash
join.
-}
module Cardano.Tx.Graph.Emit.NativeScriptRefScriptSpec (spec) where

import Data.ByteString (ByteString)
import Data.ByteString.Char8 qualified as BS8
import Data.Map.Strict qualified as Map
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
import Cardano.Ledger.Api.Scripts (Script)
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
import Cardano.Ledger.Credential (
    Credential (KeyHashObj),
    StakeReference (StakeRefNull),
 )
import Cardano.Ledger.Hashes (KeyHash (..))
import Cardano.Ledger.Keys (KeyRole (..))
import Cardano.Ledger.Mary.Value (MaryValue (..), MultiAsset (..))
import Cardano.Ledger.Shelley.Scripts (
    pattern RequireAllOf,
    pattern RequireAnyOf,
    pattern RequireMOf,
    pattern RequireSignature,
 )

import Cardano.Tx.Graph.Emit (
    EmitFormat (..),
    ResolvedUTxO,
    emit,
    serialize,
 )
import Cardano.Tx.Ledger (ConwayTx)

import Test.Hspec (Spec, describe, it, shouldSatisfy)

spec :: Spec
spec =
    describe "Cardano.Tx.Graph.Emit native reference-script tree (#13)" $ do
        it "emits a nested ScriptAll + ScriptNofK tree with signer leaves" $ do
            let bytes = emitBytes (txWithRefScript nestedNativeRefScript)
                root = sliceSubjectBlock "outputRefScript1" bytes
                threshold = sliceSubjectBlock "outputRefScript1_c2" bytes
            root `shouldSatisfy` BS8.isInfixOf "a cardano:NativeScript"
            root `shouldSatisfy` BS8.isInfixOf "a cardano:ScriptAll"
            root `shouldSatisfy` BS8.isInfixOf "cardano:hasHash _:hash_script_"
            root
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:hasChild _:outputRefScript1_c1"
            root
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:hasChild _:outputRefScript1_c2"
            root
                `shouldSatisfy` not . BS8.isInfixOf "cardano:hasRawBytes"
            sliceSubjectBlock "outputRefScript1_c1" bytes
                `shouldSatisfy` BS8.isInfixOf "a cardano:ScriptPubkey"
            sliceSubjectBlock "outputRefScript1_c1" bytes
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:requiresSigner _:cred_paymentkey_"
            threshold `shouldSatisfy` BS8.isInfixOf "a cardano:ScriptNofK"
            threshold `shouldSatisfy` BS8.isInfixOf "cardano:requiredCount 2"
            threshold
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:hasChild _:outputRefScript1_c2_c1"
            threshold
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:hasChild _:outputRefScript1_c2_c3"
        it "emits InvalidBefore and InvalidHereafter leaves with slots" $ do
            let bytes = emitBytes (txWithRefScript timelockNativeRefScript)
                before = sliceSubjectBlock "outputRefScript1_c1" bytes
                after = sliceSubjectBlock "outputRefScript1_c2" bytes
            before `shouldSatisfy` BS8.isInfixOf "a cardano:InvalidBefore"
            before `shouldSatisfy` BS8.isInfixOf "cardano:hasSlot 42"
            after `shouldSatisfy` BS8.isInfixOf "a cardano:InvalidHereafter"
            after `shouldSatisfy` BS8.isInfixOf "cardano:hasSlot 1000"

----------------------------------------------------------------------
-- Synthesis helpers
----------------------------------------------------------------------

baseTx :: ConwayTx
baseTx = mkBasicTx mkBasicTxBody

txWithRefScript :: Script ConwayEra -> ConwayTx
txWithRefScript script =
    baseTx
        & bodyTxL . outputsTxBodyL
            .~ StrictSeq.fromList
                [ mkBasicTxOut stubAddr (MaryValue (Coin 1_000_000) (MultiAsset mempty))
                    & referenceScriptTxOutL .~ SJust script
                ]

nestedNativeRefScript :: Script ConwayEra
nestedNativeRefScript =
    NativeScript $
        RequireAllOf $
            StrictSeq.fromList
                [ RequireSignature (keyHash '2')
                , RequireMOf
                    2
                    ( StrictSeq.fromList
                        [ RequireSignature (keyHash '3')
                        , RequireSignature (keyHash '4')
                        , RequireAnyOf $
                            StrictSeq.fromList
                                [ RequireSignature (keyHash '5')
                                , RequireSignature (keyHash '6')
                                ]
                        ]
                    )
                ]

timelockNativeRefScript :: Script ConwayEra
timelockNativeRefScript =
    NativeScript $
        RequireAllOf $
            StrictSeq.fromList
                [ RequireTimeStart (SlotNo 42)
                , RequireTimeExpire (SlotNo 1000)
                ]

keyHash :: Char -> KeyHash Witness
keyHash c =
    KeyHash (fromJust (hashFromStringAsHex (replicate 56 c)))

stubAddr :: Addr
stubAddr =
    Addr
        Testnet
        (KeyHashObj (KeyHash (fromJust (hashFromStringAsHex (replicate 56 '0'))) :: KeyHash Payment))
        StakeRefNull

emitBytes :: ConwayTx -> ByteString
emitBytes tx =
    case emit tx emptyUtxo [] [] of
        Right g -> serialize Turtle "native-ref-script-spec" g
        Left e -> error ("NativeScriptRefScriptSpec.emit: " <> show e)

emptyUtxo :: ResolvedUTxO
emptyUtxo = Map.empty

-- | Slice the bytes between a bnode subject anchor and the next blank line.
sliceSubjectBlock :: ByteString -> ByteString -> ByteString
sliceSubjectBlock subject bs =
    let needle = "\n_:" <> subject <> " "
     in case BS8.breakSubstring needle ("\n" <> bs) of
            (_, suf)
                | BS8.null suf -> ""
                | otherwise ->
                    let (block, _) = BS8.breakSubstring "\n\n" (BS8.drop 1 suf)
                     in block
