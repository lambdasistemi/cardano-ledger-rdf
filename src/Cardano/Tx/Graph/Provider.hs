{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Cardano.Tx.Graph.Provider
Description : HTTP CBOR providers for tx-graph (koios / blockfrost / http).
License     : Apache-2.0

@tx-graph@ can fetch a transaction's CBOR directly from an HTTP indexer
instead of reading a local file. This module owns the small set of
supported providers and the per-provider fetch.

* @koios@ — @POST \<url\>/tx_cbor@ with body @{"_tx_hashes":["\<txid\>"]}@.
  Default URL @https://api.koios.rest/api/v1@. Optional bearer token
  (Koios has a free public tier).
* @blockfrost@ — @GET \<url\>/txs/\<txid\>/cbor@. Default URL
  @https://cardano-mainnet.blockfrost.io/api/v0@. Requires a
  @project_id@ token.
* @http@ — @GET \<url\>/\<txid\>@ against a generic indexer
  (yaci-store, a custom HTTP front to db-sync, …). @--url@ is required;
  an optional bearer token is forwarded.

Every provider returns bytes accepted by
'Cardano.Tx.Decode.decodeConwayTxInput' (hex-encoded CBOR for koios /
blockfrost — the raw @.cbor@ field — or the verbatim response body for
the generic @http@ provider, which may be hex, raw CBOR, or a
cardano-cli text envelope). Emitting the resulting transaction is then
byte-identical to emitting the same CBOR read from disk, which is what
keeps the closure composable.
-}
module Cardano.Tx.Graph.Provider (
    CborProvider (..),
    ProviderConfig (..),
    ProviderError (..),
    parseProviderArg,
    renderProviderError,
    fetchCbor,
) where

import Control.Exception (SomeException, try)
import Data.Aeson (object, (.:), (.:?), (.=))
import Data.Aeson qualified as Aeson
import Data.ByteString (ByteString)
import Data.ByteString.Lazy qualified as LBS
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as Text
import Network.HTTP.Client (
    Manager,
    Request (..),
    RequestBody (RequestBodyLBS),
    httpLbs,
    parseRequest,
    responseBody,
    responseStatus,
 )
import Network.HTTP.Types.Header (Header)
import Network.HTTP.Types.Status (statusCode)

-- | The set of HTTP indexers @tx-graph@ knows how to fetch CBOR from.
data CborProvider
    = -- | Koios @tx_cbor@ batch endpoint (single-element batch here).
      Koios
    | -- | Blockfrost @\/txs\/\<hash\>\/cbor@ endpoint.
      Blockfrost
    | -- | Generic indexer: @GET \<url\>\/\<txid\>@.
      Http
    deriving stock (Eq, Show)

{- | A resolved provider request: which provider, an optional base-URL
override (required for 'Http'), and an optional auth token.
-}
data ProviderConfig = ProviderConfig
    { providerKind :: !CborProvider
    , providerUrl :: !(Maybe Text)
    , providerToken :: !(Maybe Text)
    }
    deriving stock (Eq, Show)

-- | Why a single provider fetch failed.
data ProviderError
    = -- | Transport, bad URL, or non-2xx HTTP status.
      ProviderHttpError Text
    | -- | Response body could not be parsed for the CBOR field.
      ProviderDecodeError Text
    | -- | @http@ provider invoked without @--url@.
      ProviderMissingUrl
    | -- | Provider requires a token that was not supplied.
      ProviderMissingToken Text
    deriving stock (Eq, Show)

{- | Parse the @--provider@ flag value. @file@ (and, by the caller's
default, the flag's absence) maps to 'Nothing' — meaning the positional
argument is a local CBOR path. The fetching providers map to @Just@.
-}
parseProviderArg :: String -> Either String (Maybe CborProvider)
parseProviderArg = \case
    "file" -> Right Nothing
    "koios" -> Right (Just Koios)
    "blockfrost" -> Right (Just Blockfrost)
    "http" -> Right (Just Http)
    other ->
        Left
            ( "unknown provider: "
                <> other
                <> " (expected file | koios | blockfrost | http)"
            )

-- | Render a 'ProviderError' as a single diagnostic line.
renderProviderError :: ProviderError -> Text
renderProviderError = \case
    ProviderHttpError msg -> msg
    ProviderDecodeError msg -> msg
    ProviderMissingUrl ->
        "the 'http' provider requires --url <base-url>"
    ProviderMissingToken who -> who <> " requires --token"

{- | Fetch one transaction's CBOR from the configured provider. The
@txid@ is lowercase hex (64 chars); the returned bytes are suitable to
hand straight to 'Cardano.Tx.Decode.decodeConwayTxInput'.
-}
fetchCbor ::
    Manager ->
    ProviderConfig ->
    -- | Lowercase hex txid.
    Text ->
    IO (Either ProviderError ByteString)
fetchCbor manager ProviderConfig{providerKind, providerUrl, providerToken} txid =
    case providerKind of
        Koios -> fetchKoios manager providerUrl providerToken txid
        Blockfrost -> fetchBlockfrost manager providerUrl providerToken txid
        Http -> fetchHttp manager providerUrl providerToken txid

----------------------------------------------------------------------
-- Koios
----------------------------------------------------------------------

fetchKoios ::
    Manager ->
    Maybe Text ->
    Maybe Text ->
    Text ->
    IO (Either ProviderError ByteString)
fetchKoios manager urlOverride token txid = do
    let base = fromMaybe "https://api.koios.rest/api/v1" urlOverride
        url = Text.unpack base <> "/tx_cbor"
        body = Aeson.encode (object ["_tx_hashes" .= [txid]])
        headers =
            ("content-type", "application/json")
                : bearerHeader token
    withRequest url $ \req0 -> do
        let req =
                req0
                    { method = "POST"
                    , requestHeaders = requestHeaders req0 <> headers
                    , requestBody = RequestBodyLBS body
                    }
        sendForBody manager url req (parseKoiosBody txid)

parseKoiosBody :: Text -> LBS.ByteString -> Either ProviderError ByteString
parseKoiosBody txid body =
    case Aeson.eitherDecode body of
        Left err ->
            Left
                . ProviderDecodeError
                . Text.pack
                $ "expected koios [{\"tx_hash\":..,\"cbor\":..}]: " <> err
        Right rows ->
            case lookupKoiosCbor txid rows of
                Just hex -> Right (Text.encodeUtf8 hex)
                Nothing ->
                    Left
                        . ProviderDecodeError
                        $ "koios returned no cbor for " <> txid

lookupKoiosCbor :: Text -> [KoiosRow] -> Maybe Text
lookupKoiosCbor txid rows =
    case [c | KoiosRow h (Just c) <- rows, sameHash h] of
        (c : _) -> Just c
        [] -> case [c | KoiosRow _ (Just c) <- rows] of
            (c : _) -> Just c
            [] -> Nothing
  where
    sameHash h = Text.toLower h == Text.toLower txid

data KoiosRow = KoiosRow !Text !(Maybe Text)

instance Aeson.FromJSON KoiosRow where
    parseJSON =
        Aeson.withObject "koios tx_cbor row" $ \o ->
            KoiosRow <$> o .: "tx_hash" <*> o .:? "cbor"

----------------------------------------------------------------------
-- Blockfrost
----------------------------------------------------------------------

fetchBlockfrost ::
    Manager ->
    Maybe Text ->
    Maybe Text ->
    Text ->
    IO (Either ProviderError ByteString)
fetchBlockfrost manager urlOverride token txid =
    case token of
        Nothing -> pure (Left (ProviderMissingToken "blockfrost"))
        Just projectId -> do
            let base =
                    fromMaybe
                        "https://cardano-mainnet.blockfrost.io/api/v0"
                        urlOverride
                url =
                    Text.unpack base
                        <> "/txs/"
                        <> Text.unpack txid
                        <> "/cbor"
            withRequest url $ \req0 -> do
                let req =
                        req0
                            { requestHeaders =
                                requestHeaders req0
                                    <> [("project_id", Text.encodeUtf8 projectId)]
                            }
                sendForBody manager url req parseBlockfrostBody

parseBlockfrostBody :: LBS.ByteString -> Either ProviderError ByteString
parseBlockfrostBody body =
    case Aeson.eitherDecode body of
        Left err ->
            Left
                . ProviderDecodeError
                . Text.pack
                $ "expected {\"cbor\":\"...\"}: " <> err
        Right (BlockfrostCbor hex) -> Right (Text.encodeUtf8 hex)

newtype BlockfrostCbor = BlockfrostCbor Text

instance Aeson.FromJSON BlockfrostCbor where
    parseJSON =
        Aeson.withObject "blockfrost cbor response" $ \o ->
            BlockfrostCbor <$> o .: "cbor"

----------------------------------------------------------------------
-- Generic HTTP
----------------------------------------------------------------------

fetchHttp ::
    Manager ->
    Maybe Text ->
    Maybe Text ->
    Text ->
    IO (Either ProviderError ByteString)
fetchHttp manager urlOverride token txid =
    case urlOverride of
        Nothing -> pure (Left ProviderMissingUrl)
        Just base -> do
            let url = Text.unpack base <> "/" <> Text.unpack txid
            withRequest url $ \req0 -> do
                let req =
                        req0
                            { requestHeaders =
                                requestHeaders req0 <> bearerHeader token
                            }
                sendForBody manager url req (Right . LBS.toStrict)

----------------------------------------------------------------------
-- Shared HTTP plumbing
----------------------------------------------------------------------

bearerHeader :: Maybe Text -> [Header]
bearerHeader = \case
    Nothing -> []
    Just t -> [("Authorization", Text.encodeUtf8 ("Bearer " <> t))]

{- | Parse a request URL (reporting a clean error if it is malformed)
and hand the base 'Request' to a continuation.
-}
withRequest ::
    String ->
    (Request -> IO (Either ProviderError a)) ->
    IO (Either ProviderError a)
withRequest url k = do
    parsed <- try @SomeException (parseRequest url)
    case parsed of
        Left err ->
            pure
                . Left
                . ProviderHttpError
                $ "bad URL " <> Text.pack url <> ": " <> Text.pack (show err)
        Right req -> k req

{- | Run one HTTP request, reject non-2xx statuses, and apply a
body-parsing function to the response payload.
-}
sendForBody ::
    Manager ->
    String ->
    Request ->
    (LBS.ByteString -> Either ProviderError a) ->
    IO (Either ProviderError a)
sendForBody manager url req parseBody = do
    result <- try @SomeException (httpLbs req manager)
    case result of
        Left err ->
            pure
                . Left
                . ProviderHttpError
                $ Text.pack url <> " failed: " <> Text.pack (show err)
        Right response
            | statusCode (responseStatus response) >= 400 ->
                pure
                    . Left
                    . ProviderHttpError
                    $ Text.pack url
                        <> " returned HTTP "
                        <> Text.pack
                            (show (statusCode (responseStatus response)))
            | otherwise -> pure (parseBody (responseBody response))
