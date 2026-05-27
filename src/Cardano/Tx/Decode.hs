{-# LANGUAGE TypeApplications #-}

{- |
Module      : Cardano.Tx.Decode
Description : Shared transaction and address decoders for RDF tooling.
License     : Apache-2.0

Small decoding helpers used by the CLI tools and rule loader. This module
owns input normalization only; graph construction and presentation live in
the graph/view modules.
-}
module Cardano.Tx.Decode (
    TxInputDecodeError (..),
    decodeBech32Address,
    decodeConwayTxInput,
) where

import Codec.Binary.Bech32 qualified as Bech32
import Data.Aeson ((.:))
import Data.Aeson qualified as Aeson
import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BS8
import Data.ByteString.Lazy qualified as LBS
import Data.Char (isHexDigit, isSpace)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as TextEncoding

import Cardano.Ledger.Address (Addr, decodeAddrEither)
import Cardano.Ledger.Binary (
    Annotator,
    Decoder,
    decCBOR,
    decodeFullAnnotator,
    decodeFullAnnotatorFromHexText,
    natVersion,
 )
import Cardano.Tx.Ledger (ConwayTx)

-- | Failure while decoding transaction input bytes.
newtype TxInputDecodeError = TxInputDecodeError Text
    deriving stock (Eq, Show)

{- | Decode a Conway transaction from one of the accepted CLI input forms.

The decoder accepts cardano-cli JSON text envelopes, hex-encoded CBOR, and
raw CBOR bytes.
-}
decodeConwayTxInput :: ByteString -> Either TxInputDecodeError ConwayTx
decodeConwayTxInput input =
    case Aeson.eitherDecodeStrict' input of
        Right envelope ->
            decodeConwayTxHex (txTextEnvelopeCborHex envelope)
        Left _
            | isHexInput input ->
                decodeConwayTxHex
                    (TextEncoding.decodeUtf8 (strippedHexInput input))
            | otherwise ->
                decodeConwayTxRaw input

newtype TxTextEnvelope = TxTextEnvelope
    { txTextEnvelopeCborHex :: Text
    }

instance Aeson.FromJSON TxTextEnvelope where
    parseJSON =
        Aeson.withObject "cardano-cli transaction text envelope" $ \value ->
            TxTextEnvelope <$> value .: "cborHex"

decodeConwayTxHex :: Text -> Either TxInputDecodeError ConwayTx
decodeConwayTxHex hex =
    case decodeFullAnnotatorFromHexText
        (natVersion @11)
        "Conway transaction"
        conwayTxDecoder
        (Text.strip hex) of
        Right tx ->
            Right tx
        Left err ->
            Left (TxInputDecodeError (Text.pack (show err)))

decodeConwayTxRaw :: ByteString -> Either TxInputDecodeError ConwayTx
decodeConwayTxRaw raw =
    case decodeFullAnnotator
        (natVersion @11)
        "Conway transaction"
        conwayTxDecoder
        (LBS.fromStrict raw) of
        Right tx ->
            Right tx
        Left err ->
            Left (TxInputDecodeError (Text.pack (show err)))

conwayTxDecoder :: forall s. Decoder s (Annotator ConwayTx)
conwayTxDecoder =
    decCBOR

isHexInput :: ByteString -> Bool
isHexInput input =
    let stripped = strippedHexInput input
     in not (BS.null stripped) && BS8.all isHexDigit stripped

strippedHexInput :: ByteString -> ByteString
strippedHexInput =
    BS8.filter (not . isSpace)

{- | Decode a bech32-encoded Cardano address to its ledger 'Addr'.

Returns @Left@ on any bech32 framing error, an unrecoverable data-part,
or a ledger decode failure. Mainnet (@addr1@) and testnet
(@addr_test1@) prefixes are both accepted; the loader does not pin a
network.
-}
decodeBech32Address :: Text -> Either String Addr
decodeBech32Address keyText =
    case Bech32.decodeLenient keyText of
        Left err ->
            Left ("bech32 decode failed: " <> show err)
        Right (_hrp, dataPart) ->
            case Bech32.dataPartToBytes dataPart of
                Nothing ->
                    Left "bech32 data-part not byte-aligned"
                Just bytes ->
                    case decodeAddrEither bytes of
                        Left err ->
                            Left ("ledger address decode failed: " <> err)
                        Right addr ->
                            Right addr
