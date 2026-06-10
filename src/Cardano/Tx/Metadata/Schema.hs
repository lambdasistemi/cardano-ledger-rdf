{- |
Module      : Cardano.Tx.Metadata.Schema
Description : Operator-supplied transaction metadata projection schemas.
License     : Apache-2.0

Loads @*.schema.json@ files that bind a Cardano transaction metadata
label to typed predicates in an explicit extension namespace. The
schema is intentionally generic: label meaning lives in the JSON asset,
not in the projection engine.
-}
module Cardano.Tx.Metadata.Schema (
    FieldKind (..),
    MetadataSchema (..),
    MetadataSchemaField (..),
    MetadataSchemaParseError (..),
    loadMetadataSchemaDirectory,
    renderMetadataSchemaParseError,
) where

import Control.Monad (forM)
import Data.Aeson ((.:))
import Data.Aeson qualified as Aeson
import Data.Aeson.Types (FromJSON (..), withObject, withText)
import Data.ByteString.Lazy qualified as LBS
import Data.List qualified as List
import Data.Text (Text)
import Data.Word (Word64)
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath ((</>))

-- | How a terminal metadatum node is converted into typed output.
data FieldKind
    = FieldText
    | FieldInt
    | FieldBytes
    | FieldJoinedText
    | FieldUriList
    deriving stock (Eq, Show)

-- | One projected predicate in a metadata schema.
data MetadataSchemaField = MetadataSchemaField
    { fieldPredicate :: !Text
    -- ^ Local predicate name inside 'schemaPrefix'.
    , fieldPath :: ![Text]
    -- ^ Ordered string-key path through nested @cardano:MetaMap@ nodes.
    , fieldKind :: !FieldKind
    -- ^ Terminal conversion rule.
    }
    deriving stock (Eq, Show)

-- | A label-keyed typed metadata projection schema.
data MetadataSchema = MetadataSchema
    { schemaLabel :: !Word64
    -- ^ Metadata label interpreted by this schema.
    , schemaPrefix :: !Text
    -- ^ Turtle prefix used for emitted predicates.
    , schemaNamespace :: !Text
    -- ^ Namespace IRI bound to 'schemaPrefix'.
    , schemaFields :: ![MetadataSchemaField]
    -- ^ Ordered fields; output follows this order for byte stability.
    }
    deriving stock (Eq, Show)

-- | Schema directory or file parse failure.
data MetadataSchemaParseError
    = MetadataSchemaDirectoryMissing !FilePath
    | MetadataSchemaFileError !FilePath !String
    deriving stock (Eq, Show)

instance FromJSON FieldKind where
    parseJSON =
        withText "FieldKind" $ \case
            "text" -> pure FieldText
            "int" -> pure FieldInt
            "bytes" -> pure FieldBytes
            "joinedText" -> pure FieldJoinedText
            "uriList" -> pure FieldUriList
            other -> fail ("unknown metadata field kind: " <> show other)

instance FromJSON MetadataSchemaField where
    parseJSON =
        withObject "MetadataSchemaField" $ \obj ->
            MetadataSchemaField
                <$> obj .: "predicate"
                <*> obj .: "path"
                <*> obj .: "kind"

instance FromJSON MetadataSchema where
    parseJSON =
        withObject "MetadataSchema" $ \obj ->
            MetadataSchema
                <$> obj .: "label"
                <*> obj .: "prefix"
                <*> obj .: "namespace"
                <*> obj .: "fields"

{- | Load every @*.schema.json@ file in a directory in filename order.

Malformed JSON or schema shape errors are returned with the offending
path so the CLI can mirror the existing blueprint parse diagnostics.
-}
loadMetadataSchemaDirectory ::
    FilePath ->
    IO (Either MetadataSchemaParseError [MetadataSchema])
loadMetadataSchemaDirectory dir = do
    exists <- doesDirectoryExist dir
    if not exists
        then pure (Left (MetadataSchemaDirectoryMissing dir))
        else do
            names <- listDirectory dir
            let schemaPaths =
                    [ dir </> name
                    | name <- List.sort names
                    , ".schema.json" `List.isSuffixOf` name
                    ]
            loaded <- forM schemaPaths loadMetadataSchemaFile
            pure (sequence loaded)

-- | Human-readable parse error used by @cq-rdf metadata@.
renderMetadataSchemaParseError :: MetadataSchemaParseError -> String
renderMetadataSchemaParseError = \case
    MetadataSchemaDirectoryMissing dir ->
        "metadata schema directory does not exist: " <> dir
    MetadataSchemaFileError path err ->
        "MetadataSchemaParseError: " <> path <> ": " <> err

loadMetadataSchemaFile ::
    FilePath ->
    IO (Either MetadataSchemaParseError MetadataSchema)
loadMetadataSchemaFile path = do
    bytes <- LBS.readFile path
    pure $
        case Aeson.eitherDecode bytes of
            Right schema -> Right schema
            Left err -> Left (MetadataSchemaFileError path err)
