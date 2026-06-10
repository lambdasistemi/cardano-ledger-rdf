{-# LANGUAGE TypeApplications #-}

{- |
Module      : Cardano.Tx.Graph.Emit.BodyRootSpec
Description : Body-root predicate emission (T107 / S6).
License     : Apache-2.0

Asserts the T107 / S6 invariant: the @_:tx@ subject block carries
the four Conway body-root predicates iff their corresponding
'TxBody' field is populated:

* @cardano:hasValidityInterval _:interval1@ + a separate
  @_:interval1@ sub-block carrying @cardano:intervalStart@
  and\/or @cardano:intervalEnd@ — present iff at least one of
  @invalidBefore@ \/ @invalidHereafter@ is 'SJust';
* @cardano:networkId@ — present iff @networkIdTxBodyL@ is 'SJust';
* @cardano:scriptDataHash@ — present iff
  @scriptIntegrityHashTxBodyL@ is 'SJust';
* @cardano:auxiliaryDataHash@ — present iff @auxDataHashTxBodyL@
  is 'SJust'.
* @cardano:hasCurrentTreasuryValue@ — present iff
  @currentTreasuryValueTxBodyL@ is 'SJust';
* @cardano:hasDonation@ — present iff @treasuryDonationTxBodyL@
  is a positive 'Coin'.

The legacy tx-graph fixtures leave these body-root fields
at their absent defaults; the byte-equal goldens pin the elision
branch. The populated branches are exercised here via synthetic
'ConwayTx' values built by lens-set on the 'mkBasicTxBody' default
body (no DSL combinator covers the relevant fields).
-}
module Cardano.Tx.Graph.Emit.BodyRootSpec (spec) where

import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Base16 qualified as Base16
import Data.ByteString.Char8 qualified as BS8
import Data.Map.Strict qualified as Map
import Data.Maybe (fromJust)

import Lens.Micro ((&), (.~), (^.))

import Cardano.Crypto.Hash (hashFromStringAsHex)
import Cardano.Crypto.Hash qualified as Hash
import Cardano.Ledger.Allegra.Scripts (ValidityInterval (..))
import Cardano.Ledger.Alonzo.TxBody (ScriptIntegrityHash)
import Cardano.Ledger.Api.Era (eraProtVerLow)
import Cardano.Ledger.Api.Tx (
    IsValid (..),
    auxDataTxL,
    bodyTxL,
    isValidTxL,
    mkBasicTx,
 )
import Cardano.Ledger.Api.Tx.Body (
    auxDataHashTxBodyL,
    currentTreasuryValueTxBodyL,
    mkBasicTxBody,
    networkIdTxBodyL,
    scriptIntegrityHashTxBodyL,
    treasuryDonationTxBodyL,
    vldtTxBodyL,
 )
import Cardano.Ledger.BaseTypes (
    Network (Mainnet, Testnet),
    SlotNo (..),
    StrictMaybe (SJust, SNothing),
 )
import Cardano.Ledger.Binary (serialize')
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Hashes (HASH, TxAuxDataHash (..), unsafeMakeSafeHash)

import Cardano.Tx.Decode (ConwayTx)
import Cardano.Tx.Graph.Emit (
    EmitFormat (..),
    ResolvedUTxO,
    emit,
    serialize,
 )

import Fixtures.TxGraph.S21_AuxiliaryData qualified as S21
import Fixtures.TxGraph.S22_IsValidFalse qualified as S22

import Test.Hspec (Spec, describe, it, shouldBe, shouldSatisfy)

spec :: Spec
spec = describe "Cardano.Tx.Graph.Emit body-root predicates (T107 / S6)" $ do
    validityIntervalSpecs
    networkIdSpecs
    scriptDataHashSpecs
    auxiliaryDataHashSpecs
    isValidSpecs
    currentTreasuryValueSpecs
    donationSpecs
    auxiliaryDataBodySpecs

----------------------------------------------------------------------
-- cardano:hasValidityInterval
----------------------------------------------------------------------

validityIntervalSpecs :: Spec
validityIntervalSpecs = describe "cardano:hasValidityInterval" $ do
    it "elides hasValidityInterval when both bounds are SNothing" $ do
        let bytes = emitBytes (baseTx & vldt SNothing SNothing)
        txBlockOfBytes bytes
            `shouldSatisfy` (not . BS8.isInfixOf "cardano:hasValidityInterval")
        bytes `shouldSatisfy` (not . BS8.isInfixOf "cardano:intervalStart")
        bytes `shouldSatisfy` (not . BS8.isInfixOf "cardano:intervalEnd")
    it "emits start + end when both bounds are SJust" $ do
        let bytes =
                emitBytes
                    (baseTx & vldt (SJust 1_000_000) (SJust 1_500_000))
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:hasValidityInterval _:"
        intervalBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:intervalStart 1000000"
        intervalBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:intervalEnd 1500000"
    it "emits start only when invalidHereafter is SNothing" $ do
        let bytes = emitBytes (baseTx & vldt (SJust 1_000_000) SNothing)
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:hasValidityInterval _:"
        intervalBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:intervalStart 1000000"
        intervalBlockOfBytes bytes
            `shouldSatisfy` (not . BS8.isInfixOf "cardano:intervalEnd")
    it "emits end only when invalidBefore is SNothing" $ do
        let bytes = emitBytes (baseTx & vldt SNothing (SJust 1_500_000))
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:hasValidityInterval _:"
        intervalBlockOfBytes bytes
            `shouldSatisfy` (not . BS8.isInfixOf "cardano:intervalStart")
        intervalBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:intervalEnd 1500000"

----------------------------------------------------------------------
-- cardano:networkId
----------------------------------------------------------------------

networkIdSpecs :: Spec
networkIdSpecs = describe "cardano:networkId" $ do
    it "elides networkId when SNothing" $ do
        let bytes = emitBytes baseTx
        txBlockOfBytes bytes
            `shouldSatisfy` (not . BS8.isInfixOf "cardano:networkId")
    it "emits networkId 0 for Testnet" $ do
        let bytes = emitBytes (baseTx & networkId (SJust Testnet))
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:networkId 0"
    it "emits networkId 1 for Mainnet" $ do
        let bytes = emitBytes (baseTx & networkId (SJust Mainnet))
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:networkId 1"

----------------------------------------------------------------------
-- cardano:scriptDataHash
----------------------------------------------------------------------

scriptDataHashSpecs :: Spec
scriptDataHashSpecs = describe "cardano:scriptDataHash" $ do
    it "elides scriptDataHash when SNothing" $ do
        let bytes = emitBytes baseTx
        txBlockOfBytes bytes
            `shouldSatisfy` (not . BS8.isInfixOf "cardano:scriptDataHash")
    it "emits scriptDataHash Identifier bnode when SJust (T122c)" $ do
        let h = stubScriptIntegrityHash 0xaa
            bytes = emitBytes (baseTx & scriptDataHash (SJust h))
            hex = BS8.replicate 64 'a'
        -- T122c / #56: hash is now an Identifier-typed IRI,
        -- not a flat string literal.
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf
                "cardano:scriptDataHash <urn:cardano:id:ScriptDataHash:"
        bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:leafType \"ScriptDataHash\""
        bytes
            `shouldSatisfy` BS8.isInfixOf
                ("cardano:bytesHex \"" <> hex <> "\"")

----------------------------------------------------------------------
-- cardano:auxiliaryDataHash
----------------------------------------------------------------------

auxiliaryDataHashSpecs :: Spec
auxiliaryDataHashSpecs = describe "cardano:auxiliaryDataHash" $ do
    it "elides auxiliaryDataHash when SNothing" $ do
        let bytes = emitBytes baseTx
        txBlockOfBytes bytes
            `shouldSatisfy` (not . BS8.isInfixOf "cardano:auxiliaryDataHash")
    it "emits auxiliaryDataHash Identifier bnode when SJust (T122c)" $ do
        let h = TxAuxDataHash (unsafeMakeSafeHash (rawHash 0xbb))
            bytes = emitBytes (baseTx & auxDataHash (SJust h))
            hex = BS8.replicate 64 'b'
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf
                "cardano:auxiliaryDataHash <urn:cardano:id:AuxiliaryDataHash:"
        bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:leafType \"AuxiliaryDataHash\""
        bytes
            `shouldSatisfy` BS8.isInfixOf
                ("cardano:bytesHex \"" <> hex <> "\"")

----------------------------------------------------------------------
-- cardano:isValid
----------------------------------------------------------------------

isValidSpecs :: Spec
isValidSpecs = describe "cardano:isValid" $ do
    it "emits true unconditionally for the default transaction flag" $ do
        let bytes = emitBytes baseTx
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf
                "cardano:isValid \"true\"^^xsd:boolean"
    it "emits false when isValidTxL is IsValid False" $ do
        let IsValid flag = S22.tx ^. isValidTxL
            bytes = emitBytes S22.tx
        flag `shouldBe` False
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf
                "cardano:isValid \"false\"^^xsd:boolean"

----------------------------------------------------------------------
-- cardano:hasCurrentTreasuryValue
----------------------------------------------------------------------

currentTreasuryValueSpecs :: Spec
currentTreasuryValueSpecs = describe "cardano:hasCurrentTreasuryValue" $ do
    it "elides current treasury value when SNothing" $ do
        let bytes = emitBytes baseTx
        txBlockOfBytes bytes
            `shouldSatisfy` (not . BS8.isInfixOf "cardano:hasCurrentTreasuryValue")
    it "emits current treasury value when SJust" $ do
        let bytes = emitBytes (baseTx & currentTreasuryValue (SJust (Coin 90_000_000)))
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf
                "cardano:hasCurrentTreasuryValue 90000000"

----------------------------------------------------------------------
-- cardano:hasDonation
----------------------------------------------------------------------

donationSpecs :: Spec
donationSpecs = describe "cardano:hasDonation" $ do
    it "elides donation when the ledger default is zero" $ do
        let bytes = emitBytes baseTx
        txBlockOfBytes bytes
            `shouldSatisfy` (not . BS8.isInfixOf "cardano:hasDonation")
    it "emits donation when positive" $ do
        let bytes = emitBytes (baseTx & donation (Coin 1_000_000))
        txBlockOfBytes bytes
            `shouldSatisfy` BS8.isInfixOf "cardano:hasDonation 1000000"

----------------------------------------------------------------------
-- cardano:hasAuxiliaryData
----------------------------------------------------------------------

auxiliaryDataBodySpecs :: Spec
auxiliaryDataBodySpecs = describe "cardano:hasAuxiliaryData" $ do
    it "elides auxiliary data body when auxDataTxL is SNothing" $ do
        let bytes = emitBytes baseTx
        txBlockOfBytes bytes
            `shouldSatisfy` (not . BS8.isInfixOf "cardano:hasAuxiliaryData")
    it "emits auxiliary data raw CBOR bytes when auxDataTxL is SJust" $ do
        case S21.tx ^. auxDataTxL of
            SNothing -> error "S21.tx unexpectedly has no auxiliary data"
            SJust auxData -> do
                let bytes = emitBytes S21.tx
                    rawHex =
                        Base16.encode $
                            serialize' (eraProtVerLow @ConwayEra) auxData
                txBlockOfBytes bytes
                    `shouldSatisfy` BS8.isInfixOf
                        "cardano:hasAuxiliaryData _:"
                auxiliaryDataBlockOfBytes bytes
                    `shouldSatisfy` BS8.isInfixOf "a cardano:AuxiliaryData"
                auxiliaryDataBlockOfBytes bytes
                    `shouldSatisfy` BS8.isInfixOf "a cardano:OpaqueLeaf"
                auxiliaryDataBlockOfBytes bytes
                    `shouldSatisfy` BS8.isInfixOf
                        ("cardano:hasRawBytes \"" <> rawHex <> "\"")

----------------------------------------------------------------------
-- Synthesis helpers
----------------------------------------------------------------------

{- | An empty Conway tx: zero inputs, zero outputs, zero of everything.
All four body-root predicate fields default to 'SNothing' \/
@ValidityInterval SNothing SNothing@.
-}
baseTx :: ConwayTx
baseTx = mkBasicTx mkBasicTxBody

-- | Set the body's 'ValidityInterval'.
vldt ::
    StrictMaybe SlotNo ->
    StrictMaybe SlotNo ->
    ConwayTx ->
    ConwayTx
vldt before after =
    bodyTxL . vldtTxBodyL .~ ValidityInterval before after

-- | Set the body's @networkIdTxBodyL@.
networkId :: StrictMaybe Network -> ConwayTx -> ConwayTx
networkId n = bodyTxL . networkIdTxBodyL .~ n

-- | Set the body's @scriptIntegrityHashTxBodyL@.
scriptDataHash ::
    StrictMaybe ScriptIntegrityHash -> ConwayTx -> ConwayTx
scriptDataHash h = bodyTxL . scriptIntegrityHashTxBodyL .~ h

-- | Set the body's @auxDataHashTxBodyL@.
auxDataHash :: StrictMaybe TxAuxDataHash -> ConwayTx -> ConwayTx
auxDataHash h = bodyTxL . auxDataHashTxBodyL .~ h

-- | Set the body's @currentTreasuryValueTxBodyL@.
currentTreasuryValue :: StrictMaybe Coin -> ConwayTx -> ConwayTx
currentTreasuryValue value =
    bodyTxL . currentTreasuryValueTxBodyL .~ value

-- | Set the body's @treasuryDonationTxBodyL@.
donation :: Coin -> ConwayTx -> ConwayTx
donation value = bodyTxL . treasuryDonationTxBodyL .~ value

{- | A 32-byte 'ScriptIntegrityHash' filled with the given byte
(0..255). Used to exercise the @cardano:scriptDataHash@ branch
without routing through CBOR.
-}
stubScriptIntegrityHash :: Int -> ScriptIntegrityHash
stubScriptIntegrityHash = unsafeMakeSafeHash . rawHash

-- | A raw 32-byte 'Hash' filled with the given byte (0..255).
rawHash :: Int -> Hash.Hash HASH a
rawHash b =
    fromJust (hashFromStringAsHex (concat (replicate 32 (hexByte b))))
  where
    hexByte n = [d (n `div` 16), d (n `mod` 16)]
    d k = "0123456789abcdef" !! k

----------------------------------------------------------------------
-- Bytes helpers
----------------------------------------------------------------------

emitBytes :: ConwayTx -> ByteString
emitBytes tx =
    case emit tx emptyUtxo [] [] of
        Right g -> serialize Turtle "body-root-spec" g
        Left e -> error ("BodyRootSpec.emit: " <> show e)

emptyUtxo :: ResolvedUTxO
emptyUtxo = Map.empty

{- | The transaction subject block — bytes from the
@cardano:Transaction@ anchor to the next blank line.
-}
txBlockOfBytes :: ByteString -> ByteString
txBlockOfBytes = sliceBlockContaining " a cardano:Transaction"

{- | The @_:interval1@ subject sub-block — bytes from the
@_:interval1@ subject-position anchor (after the blank line
that separates it from the parent @_:tx@ block) to the next
blank line. Returns @""@ when no such block exists. The
@"\n\n_:interval1 "@ pattern dodges the object-position
occurrence of @_:interval1@ inside the parent block.
-}
intervalBlockOfBytes :: ByteString -> ByteString
intervalBlockOfBytes = sliceBlockContaining "cardano:interval"

-- | The @_:auxiliaryData1@ subject sub-block. Returns @""@ when absent.
auxiliaryDataBlockOfBytes :: ByteString -> ByteString
auxiliaryDataBlockOfBytes = sliceBlockContaining " a cardano:AuxiliaryData"

sliceBlockContaining :: ByteString -> ByteString -> ByteString
sliceBlockContaining needle =
    headOrEmpty . filter (BS8.isInfixOf needle) . blocks
  where
    headOrEmpty [] = ""
    headOrEmpty (x : _) = x

    blocks input =
        case BS8.breakSubstring "\n\n" input of
            (block, rest)
                | BS.null rest -> [block]
                | otherwise -> block : blocks (BS8.drop 2 rest)
