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
import Data.Maybe (listToMaybe, mapMaybe)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as TextEncoding
import Data.Text.Encoding.Error (lenientDecode)
import Data.Text.Read qualified as TextRead
import Data.Word (Word64)

import Cardano.Tx.Metadata.Schema (
    FieldKind (..),
    MetadataSchema (..),
    MetadataSchemaField (..),
 )

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
enrichMetadataTurtle schemas ttlBytes = do
    let ttlText = TextEncoding.decodeUtf8With lenientDecode ttlBytes
        graph = parseCanonicalTurtle ttlText
        projections = metadataProjections schemas graph ttlText
        decorations = concatMap snd projections
    pure $
        if null decorations
            then ttlBytes
            else
                ttlBytes
                    <> ensureTrailingNewline ttlBytes
                    <> TextEncoding.encodeUtf8
                        ( Text.intercalate "\n" $
                            prefixDirectives projections
                                <> [ ""
                                   , "#"
                                   , "# Metadata typed projection."
                                   , "#"
                                   , ""
                                   ]
                                <> decorations
                                <> [""]
                        )

metadataProjections ::
    [MetadataSchema] ->
    TurtleGraph ->
    Text ->
    [(MetadataSchema, [Text])]
metadataProjections schemas graph fullText =
    filter (not . null . snd) $
        concatMap decorateTx (Map.toList (tgBlocks graph))
  where
    decorateTx (txSubj, txBlock)
        | not ("cardano:Transaction" `Text.isInfixOf` txBlock) = []
        | otherwise =
            case objectFor "cardano:hasAuxiliaryData" txBlock of
                Nothing -> []
                Just auxSubj ->
                    decorateAux txSubj auxSubj

    decorateAux txSubj auxSubj =
        case Map.lookup auxSubj (tgBlocks graph) of
            Nothing -> []
            Just auxBlock ->
                [ (schema, linesOut)
                | entrySubj <- objectsFor "cardano:hasMetadatum" auxBlock
                , Just entryBlock <- [Map.lookup entrySubj (tgBlocks graph)]
                , Just label <- [metadataLabel entryBlock]
                , schema <- schemasForLabel label
                , let linesOut = schemaLines txSubj entryBlock schema
                ]

    schemasForLabel label =
        [schema | schema <- schemas, schemaLabel schema == label]

    schemaLines txSubj entryBlock schema =
        fromMaybeLines $ do
            rootSubj <-
                maybe
                    (Left "missing cardano:metadatumValue")
                    Right
                    (objectFor "cardano:metadatumValue" entryBlock)
            rendered <- traverse (projectField graph rootSubj) (schemaFields schema)
            let linesOut =
                    zipWith
                        (renderProjection txSubj schema)
                        (schemaFields schema)
                        rendered
            if any (`Text.isInfixOf` fullText) (projectedPredicates schema)
                then Right []
                else Right linesOut

    fromMaybeLines = \case
        Right linesOut -> linesOut
        Left _err -> []

metadataLabel :: Text -> Maybe Word64
metadataLabel block = do
    raw <- objectFor "cardano:metadataLabel" block
    case TextRead.decimal raw of
        Right (n, rest) | Text.null rest -> Just n
        _ -> Nothing

projectField ::
    TurtleGraph ->
    Text ->
    MetadataSchemaField ->
    Either Text Text
projectField graph rootSubj MetadataSchemaField{fieldPath, fieldKind} = do
    terminal <- resolvePath graph rootSubj fieldPath
    terminalBlock <-
        maybe
            (Left ("missing node " <> terminal))
            Right
            (Map.lookup terminal (tgBlocks graph))
    case fieldKind of
        FieldText ->
            turtleString <$> requireLiteral "cardano:textValue" terminalBlock
        FieldInt ->
            requireObject "cardano:intValue" terminalBlock
        FieldBytes ->
            turtleString <$> requireLiteral "cardano:bytesHex" terminalBlock
        FieldJoinedText ->
            Left "joinedText is not implemented in this slice"
        FieldUriList ->
            Left "uriList is not implemented in this slice"

resolvePath :: TurtleGraph -> Text -> [Text] -> Either Text Text
resolvePath _graph current [] =
    Right current
resolvePath graph current (key : rest) = do
    next <- mapLookupText graph current key
    resolvePath graph next rest

mapLookupText :: TurtleGraph -> Text -> Text -> Either Text Text
mapLookupText graph mapSubj key = do
    mapBlock <-
        maybe
            (Left ("missing map node " <> mapSubj))
            Right
            (Map.lookup mapSubj (tgBlocks graph))
    case listToMaybe (matchingEntries mapBlock) of
        Just valueSubj -> Right valueSubj
        Nothing -> Left ("missing key " <> key)
  where
    matchingEntries mapBlock =
        [ valueSubj
        | entrySubj <- objectsFor "cardano:hasEntry" mapBlock
        , Just entryBlock <- [Map.lookup entrySubj (tgBlocks graph)]
        , Just keySubj <- [objectFor "cardano:metaKey" entryBlock]
        , Just keyBlock <- [Map.lookup keySubj (tgBlocks graph)]
        , literalFor "cardano:textValue" keyBlock == Just key
        , Just valueSubj <- [objectFor "cardano:metaValue" entryBlock]
        ]

requireObject :: Text -> Text -> Either Text Text
requireObject predName block =
    maybe
        (Left ("missing object " <> predName))
        Right
        (objectFor predName block)

requireLiteral :: Text -> Text -> Either Text Text
requireLiteral predName block =
    maybe
        (Left ("missing literal " <> predName))
        Right
        (literalFor predName block)

renderProjection ::
    Text ->
    MetadataSchema ->
    MetadataSchemaField ->
    Text ->
    Text
renderProjection txSubj MetadataSchema{schemaPrefix} MetadataSchemaField{fieldPredicate} renderedObject =
    txSubj
        <> " "
        <> schemaPrefix
        <> ":"
        <> fieldPredicate
        <> " "
        <> renderedObject
        <> " ."

projectedPredicates :: MetadataSchema -> [Text]
projectedPredicates MetadataSchema{schemaPrefix, schemaFields} =
    [ schemaPrefix <> ":" <> fieldPredicate
    | MetadataSchemaField{fieldPredicate} <- schemaFields
    ]

prefixDirectives :: [(MetadataSchema, [Text])] -> [Text]
prefixDirectives projections =
    [ "@prefix " <> prefix <> ": <" <> namespace <> "> ."
    | (prefix, namespace) <-
        List.nub
            [ (schemaPrefix schema, schemaNamespace schema)
            | (schema, _linesOut) <- projections
            ]
    ]

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
        objectFromCanonicalLine predName line

objectsFor :: Text -> Text -> [Text]
objectsFor predName block =
    mapMaybe (objectFromCanonicalLine predName) (Text.lines block)

objectFromCanonicalLine :: Text -> Text -> Maybe Text
objectFromCanonicalLine predName line = do
    rest <- Text.stripPrefix predName (Text.strip (dropSubject line))
    pure (stripObject rest)
  where
    dropSubject rawLine =
        let stripped = Text.strip rawLine
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
