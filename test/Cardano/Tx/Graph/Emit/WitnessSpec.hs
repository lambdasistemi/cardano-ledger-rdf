{- |
Module      : Cardano.Tx.Graph.Emit.WitnessSpec
Description : Witness-set walker invariants (T128b / S31).
License     : Apache-2.0

Per-witness-type invariants on the joint Turtle output of the
body emitter when a synthetic 'ConwayTx' carries non-empty
witness-set fields. Each test populates one witness collection
on @baseTx@ via the appropriate @witsTxL@ sub-lens and asserts
the expected predicate shape lands in the emitted bytes.

Compose with 'Cardano.Tx.Graph.EmitGoldenSpec' (full triple
pins) and 'Cardano.Tx.Graph.Emit.ExhaustivitySpec' (dispatcher
coverage) — this spec is the per-witness-shape contract.
-}
module Cardano.Tx.Graph.Emit.WitnessSpec (spec) where

import Data.ByteString (ByteString)
import Data.ByteString.Char8 qualified as BS8
import Data.Map.Strict qualified as Map

import Lens.Micro ((&), (.~))
import PlutusCore.Data qualified as PLC

import Cardano.Ledger.Alonzo.Scripts (
    AlonzoScript (NativeScript),
    AsIx (..),
 )
import Cardano.Ledger.Alonzo.TxWits (Redeemers (..), TxDats (..))
import Cardano.Ledger.Api.Tx (bodyTxL, mkBasicTx, witsTxL)
import Cardano.Ledger.Api.Tx.Body (
    mkBasicTxBody,
    reqSignerHashesTxBodyL,
 )
import Cardano.Ledger.Api.Tx.Wits (
    datsTxWitsL,
    rdmrsTxWitsL,
    scriptTxWitsL,
 )
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.Scripts (ConwayPlutusPurpose (..))
import Cardano.Ledger.Core (Script, hashScript)
import Cardano.Ledger.Hashes (DataHash, KeyHash (..), ScriptHash)
import Cardano.Ledger.Keys (KeyRole (..))
import Cardano.Ledger.Plutus.Data (Data (..), hashData)
import Cardano.Ledger.Plutus.ExUnits (ExUnits (..))

import Data.Maybe (fromJust)
import Data.Sequence.Strict qualified as StrictSeq
import Data.Set qualified as Set

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Ledger.Shelley.Scripts (
    pattern RequireMOf,
    pattern RequireSignature,
 )

import Cardano.Tx.Decode (ConwayTx)
import Cardano.Tx.Graph.Emit (
    EmitFormat (..),
    ResolvedUTxO,
    emit,
    serialize,
 )

import Test.Hspec (Spec, describe, it, shouldSatisfy)

spec :: Spec
spec = describe "Cardano.Tx.Graph.Emit witness set (T128b / S31)" $ do
    describe "empty witness set" $ do
        it "elides every cardano:hasX witness edge on _:tx" $ do
            let bytes = emitBytes baseTx
            bytes `shouldSatisfy` (not . BS8.isInfixOf "cardano:hasRedeemer")
            bytes `shouldSatisfy` (not . BS8.isInfixOf "cardano:hasKeyWitness")
            bytes `shouldSatisfy` (not . BS8.isInfixOf "cardano:hasDatumWitness")
            bytes `shouldSatisfy` (not . BS8.isInfixOf "cardano:hasScriptWitness")
            bytes `shouldSatisfy` (not . BS8.isInfixOf "cardano:hasBootstrapWitness")
        it "does not emit a Witness-set section header" $ do
            let bytes = emitBytes baseTx
            bytes `shouldSatisfy` (not . BS8.isInfixOf "Witness set")
    describe "redeemer witness" $ do
        let bytes = emitBytes txWithRedeemer
        it "emits cardano:hasRedeemer on _:tx" $
            bytes `shouldSatisfy` BS8.isInfixOf "cardano:hasRedeemer _:"
        it "emits the redeemer Class anchor" $
            bytes `shouldSatisfy` BS8.isInfixOf "_redeemer1 a cardano:Redeemer"
        it "emits hasPurpose / hasIndex / hasData / hasExUnits" $ do
            bytes `shouldSatisfy` BS8.isInfixOf "cardano:hasPurpose \"Spend\""
            bytes `shouldSatisfy` BS8.isInfixOf "cardano:hasIndex 0"
            bytes `shouldSatisfy` BS8.isInfixOf "cardano:hasData _:"
            bytes `shouldSatisfy` BS8.isInfixOf "_redeemerData1"
            bytes `shouldSatisfy` BS8.isInfixOf "cardano:hasExUnits _:"
            bytes `shouldSatisfy` BS8.isInfixOf "_exUnits1"
        it "emits the ExUnits sub-block with memoryUnits + cpuUnits" $ do
            bytes `shouldSatisfy` BS8.isInfixOf "_exUnits1 a cardano:ExUnits"
            bytes `shouldSatisfy` BS8.isInfixOf "cardano:memoryUnits 100"
            bytes `shouldSatisfy` BS8.isInfixOf "cardano:cpuUnits 200"
    describe "datum witness" $ do
        let bytes = emitBytes txWithDatumWitness
        it "emits cardano:hasDatumWitness on _:tx" $ do
            bytes
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:hasDatumWitness _:"
            bytes `shouldSatisfy` BS8.isInfixOf "_dataWitness1"
        it "binds the datum-witness bnode to cardano:Datum" $
            bytes
                `shouldSatisfy` BS8.isInfixOf
                    "_dataWitness1 a cardano:Datum"
        it "carries hasHash (shared DatumHash identifier) + hasRawBytes" $ do
            bytes
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:hasHash <urn:cardano:id:DatumHash:"
            bytes `shouldSatisfy` BS8.isInfixOf "cardano:hasRawBytes"
    describe "script witness" $ do
        let bytes = emitBytes txWithScriptWitness
        it "emits cardano:hasScriptWitness on _:tx" $ do
            bytes
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:hasScriptWitness _:"
            bytes `shouldSatisfy` BS8.isInfixOf "_scriptWitness1"
        it "types the witness-set script as cardano:NativeScript (stub)" $
            bytes
                `shouldSatisfy` BS8.isInfixOf
                    "_scriptWitness1 a cardano:NativeScript"
        it "carries hasHash and typed native-script leaves, not hasRawBytes" $ do
            bytes
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:hasHash <urn:cardano:id:ScriptHash:"
            sliceSubjectBlock "scriptWitness1" bytes
                `shouldSatisfy` BS8.isInfixOf "a cardano:ScriptNofK"
            sliceSubjectBlock "scriptWitness1" bytes
                `shouldSatisfy` BS8.isInfixOf "cardano:requiredCount 1"
            sliceSubjectBlock "scriptWitness1_c1" bytes
                `shouldSatisfy` BS8.isInfixOf "a cardano:ScriptPubkey"
            sliceSubjectBlock "scriptWitness1_c1" bytes
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:requiresSigner <urn:cardano:id:PaymentKey:"
            sliceSubjectBlock "scriptWitness1" bytes
                `shouldSatisfy` not . BS8.isInfixOf "cardano:hasRawBytes"
    describe "shared verification-key bnode (T128b shared-identity)" $ do
        let bytes = emitBytes txWithSharedSignerAndKeyWit
        -- The body-side hasRequiredSigner and the (synthetic but
        -- here-empty) key-witness hasVerificationKey both resolve
        -- to the same @_:cred_paymentkey_<hex>@ bnode via the
        -- shared 'resolveCredentialAndIntroduceIdent' helper. The
        -- key-witness side is hard to populate without crypto, so
        -- the cross-section assertion here is that the
        -- required-signer Identifier block exists and the
        -- shared-bnode anchor is reachable for SPARQL joins.
        it "carries the PaymentKey Identifier block" $ do
            bytes `shouldSatisfy` BS8.isInfixOf "a cardano:Identifier"
            bytes
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:leafType \"PaymentKey\""

----------------------------------------------------------------------
-- Fixtures
----------------------------------------------------------------------

emptyUtxo :: ResolvedUTxO
emptyUtxo = Map.empty

baseTx :: ConwayTx
baseTx = mkBasicTx mkBasicTxBody

emitBytes :: ConwayTx -> ByteString
emitBytes tx =
    case emit tx emptyUtxo [] [] of
        Right g -> serialize Turtle "witness-spec" g
        Left e -> error ("WitnessSpec.emit: " <> show e)

stubDatumData :: Data ConwayEra
stubDatumData = Data (PLC.I 42)

stubDatumHash :: DataHash
stubDatumHash = hashData stubDatumData

stubExUnits :: ExUnits
stubExUnits = ExUnits 100 200

stubRedeemerPurpose :: ConwayPlutusPurpose AsIx ConwayEra
stubRedeemerPurpose = ConwaySpending (AsIx 0)

stubScriptHash :: ScriptHash
stubScriptHash = hashScript (nativeWitnessScript :: Script ConwayEra)

nativeWitnessScript :: Script ConwayEra
nativeWitnessScript =
    NativeScript $
        RequireMOf
            1
            ( StrictSeq.fromList
                [ RequireSignature (witnessScriptKeyHash 'b')
                , RequireSignature (witnessScriptKeyHash 'c')
                ]
            )

witnessScriptKeyHash :: Char -> KeyHash Witness
witnessScriptKeyHash c =
    KeyHash (fromJust (hashFromStringAsHex (replicate 56 c)))

stubKeyHash :: KeyHash Guard
stubKeyHash =
    KeyHash (fromJust (hashFromStringAsHex (replicate 56 'a')))

txWithDatumWitness :: ConwayTx
txWithDatumWitness =
    baseTx
        & witsTxL . datsTxWitsL
            .~ TxDats (Map.singleton stubDatumHash stubDatumData)

txWithRedeemer :: ConwayTx
txWithRedeemer =
    baseTx
        & witsTxL . rdmrsTxWitsL
            .~ Redeemers
                ( Map.singleton
                    stubRedeemerPurpose
                    (stubDatumData, stubExUnits)
                )

txWithScriptWitness :: ConwayTx
txWithScriptWitness =
    baseTx
        & witsTxL . scriptTxWitsL
            .~ Map.singleton stubScriptHash nativeWitnessScript

{- | A tx whose body declares a required signer; the SPARQL-join
invariant for the witness-set walker is that any key-witness
emitted for the same key-hash binds @hasVerificationKey@ to the
SAME @_:cred_paymentkey_…@ bnode the required-signer side
emits. The required-signer side is the anchor; the key-witness
side cannot be synthesized cheaply (real DSIGN signature
required), so the body-side anchor is sufficient to assert the
shared Identifier bnode shape.
-}
txWithSharedSignerAndKeyWit :: ConwayTx
txWithSharedSignerAndKeyWit =
    baseTx
        & bodyTxL . reqSignerHashesTxBodyL .~ Set.singleton stubKeyHash

-- | Slice the bytes between a bnode subject anchor and the next blank line.
sliceSubjectBlock :: ByteString -> ByteString -> ByteString
sliceSubjectBlock subject bs =
    let needle = "_" <> subject <> " "
     in case filter (blockStartsWith needle) (blocks bs) of
            [] -> ""
            block : _ -> block
  where
    blockStartsWith needle block =
        case BS8.lines block of
            [] -> False
            firstLine : _ -> needle `BS8.isInfixOf` firstLine

    blocks input =
        case BS8.breakSubstring "\n\n" input of
            (block, rest)
                | BS8.null rest -> [block]
                | otherwise -> block : blocks (BS8.drop 2 rest)
