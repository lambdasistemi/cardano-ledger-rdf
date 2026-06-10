{- |
Module      : Cardano.Tx.Metadata.Project
Description : Typed projection over generic transaction metadata RDF.
License     : Apache-2.0

Projects the generic @cardano:@ metadatum tree into schema-declared
extension predicates. The module also owns the small canonical Turtle
scanner used by the existing blueprint pass and the metadata pass; it is
not a general RDF parser.
-}
module Cardano.Tx.Metadata.Project (
    TurtleGraph (..),
    enrichMetadataTurtle,
    ensureTrailingNewline,
    literalFor,
    objectFor,
    parseCanonicalTurtle,
    turtleString,
) where

import Control.Applicative (asum)
import Data.ByteString qualified as BS
import Data.List qualified as List
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.Text (Text)
import Data.Text qualified as Text

import Cardano.Tx.Metadata.Schema (MetadataSchema)

-- | Subject-indexed blocks from the repository's canonical Turtle output.
newtype TurtleGraph = TurtleGraph
    { tgBlocks :: Map Text Text
    }

{- | Enrich a Turtle byte stream with typed metadata triples.

The foundational slice wires the pass into the CLI. User-story slices add
the schema-driven decorations while keeping this function's contract
stable.
-}
enrichMetadataTurtle ::
    [MetadataSchema] ->
    BS.ByteString ->
    IO BS.ByteString
enrichMetadataTurtle _schemas ttlBytes =
    pure ttlBytes

-- | Parse canonical Turtle into subject blocks.
parseCanonicalTurtle :: Text -> TurtleGraph
parseCanonicalTurtle =
    TurtleGraph . Map.fromList . mapMaybe parseBlock . splitStatements

splitStatements :: Text -> [Text]
splitStatements = go [] [] . Text.lines
  where
    go acc current [] =
        reverse (finish current acc)
    go acc current (line : rest)
        | skipLine line && null current = go acc [] rest
        | statementEnd line =
            go (Text.unlines (reverse (line : current)) : acc) [] rest
        | otherwise = go acc (line : current) rest
    finish [] acc = acc
    finish current acc = Text.unlines (reverse current) : acc
    skipLine line =
        let t = Text.strip line
         in Text.null t || "#" `Text.isPrefixOf` t || "@prefix" `Text.isPrefixOf` t
    statementEnd line = "." `Text.isSuffixOf` Text.strip line

parseBlock :: Text -> Maybe (Text, Text)
parseBlock block = do
    firstLine <- List.find (not . Text.null . Text.strip) (Text.lines block)
    subject <- listToMaybeText (Text.words firstLine)
    pure (subject, block)

listToMaybeText :: [Text] -> Maybe Text
listToMaybeText [] = Nothing
listToMaybeText (x : _) = Just x

-- | Find the first object for a predicate inside a canonical block.
objectFor :: Text -> Text -> Maybe Text
objectFor predName block =
    asum (map objectFromLine (Text.lines block))
  where
    objectFromLine line = do
        rest <- Text.stripPrefix predName (Text.strip (dropSubject line))
        pure (stripObject rest)
    dropSubject line =
        let stripped = Text.strip line
         in case Text.words stripped of
                _subject : pred0 : more
                    | pred0 == predName -> Text.unwords (pred0 : more)
                _ -> stripped
    stripObject =
        Text.strip
            . Text.dropWhileEnd (`elem` [';', '.'])
            . Text.strip

-- | Find the first quoted string literal for a predicate.
literalFor :: Text -> Text -> Maybe Text
literalFor predName block = do
    obj <- objectFor predName block
    quotedText obj

quotedText :: Text -> Maybe Text
quotedText t =
    case Text.uncons (Text.strip t) of
        Just ('"', rest) ->
            Just (Text.takeWhile (/= '"') rest)
        _ -> Nothing

-- | Render a Turtle string literal.
turtleString :: Text -> Text
turtleString t =
    "\"" <> Text.concatMap escapeChar t <> "\""
  where
    escapeChar = \case
        '"' -> "\\\""
        '\\' -> "\\\\"
        '\n' -> "\\n"
        c -> Text.singleton c

-- | Bytes needed to separate appended Turtle from the input.
ensureTrailingNewline :: BS.ByteString -> BS.ByteString
ensureTrailingNewline bs
    | BS.null bs = BS.empty
    | BS.last bs == 0x0A = BS.empty
    | otherwise = "\n"
