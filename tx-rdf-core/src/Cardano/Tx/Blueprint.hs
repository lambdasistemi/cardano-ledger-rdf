{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Cardano.Tx.Blueprint
Description : Plutus blueprint parsing for transaction graph typing.
License     : Apache-2.0

This module parses the CIP-0057 subset needed by the graph blueprint
boundary: validators, datum and redeemer argument schemas, definitions, and
the Plutus data schema forms needed to name constructor fields.

The parsed 'Blueprint' value drives
'Cardano.Tx.Graph.Emit.Blueprint.decodeDatumForOutput' and
'Cardano.Tx.Graph.Emit.Blueprint.decodeRedeemerForPurpose', which the
projection walker consults to render typed @cardano:hasField@ predicates
in place of opaque @cardano:hasRawBytes@ when a script hash matches a
loaded blueprint. The schema vocabulary tracks CIP-0057 closely enough to
re-emit constructor and field names verbatim, but it does not attempt full
CIP-0057 coverage — collections, abstract definitions, and value-only
fields fall outside the structural decoder's responsibility.
-}
module Cardano.Tx.Blueprint (
    Blueprint (..),
    BlueprintArgument (..),
    BlueprintArgumentKind (..),
    BlueprintArgumentSelector (..),
    BlueprintDataError (..),
    BlueprintMatchError (..),
    BlueprintPreamble (..),
    BlueprintSchema (..),
    BlueprintSchemaKind (..),
    BlueprintValidator (..),
    OpenValue (..),
    decodeMatchingBlueprintArgument,
    decodeBlueprintData,
    matchBlueprintArgument,
    parseBlueprintJSON,
    resolveBlueprintSchema,
) where

import Data.Aeson (
    FromJSON (..),
    Object,
    eitherDecode,
    withObject,
    (.:),
    (.:?),
 )
import Data.Aeson qualified as Aeson
import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KeyMap
import Data.Aeson.Types (Parser, parseEither, (.!=))
import Data.ByteString qualified as BS
import Data.ByteString.Base16 qualified as Base16
import Data.ByteString.Lazy qualified as LBS
import Data.Foldable (toList)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as TextEncoding

import Cardano.Ledger.Api.Scripts.Data (Data (..))
import Cardano.Ledger.Conway (ConwayEra)
import PlutusCore.Data qualified as PLC

{- | A CIP-0057 Plutus blueprint as parsed from JSON: the preamble that
describes the on-chain code, the list of validators it exposes, and a
definitions table that names every shared schema referenced by
'SchemaReference'.
-}
data Blueprint = Blueprint
    { blueprintPreamble :: BlueprintPreamble
    -- ^ Header metadata (title, Plutus version) carried verbatim from
    -- the @preamble@ object.
    , blueprintValidators :: [BlueprintValidator]
    -- ^ Every @validators[i]@ entry in source order. The order is not
    -- semantically meaningful but is preserved so error messages can
    -- point at a stable position.
    , blueprintDefinitions :: Map Text BlueprintSchema
    -- ^ Reusable schemas keyed by their JSON-Pointer-style reference name
    -- (the part after @#\/definitions\/@). Consulted by
    -- 'resolveBlueprintSchema' when walking 'SchemaReference' edges.
    }
    deriving stock (Eq, Show)

{- | Header metadata for a 'Blueprint'. Title and Plutus version are kept
as 'Text' so the surrounding tooling can render them without coupling
to the CIP-0057 schema vocabulary.
-}
data BlueprintPreamble = BlueprintPreamble
    { preambleTitle :: Text
    -- ^ The blueprint-level title (e.g. the contract name).
    , preamblePlutusVersion :: Text
    -- ^ The targeted Plutus Core version, verbatim from the @plutusVersion@
    -- field (e.g. @"v2"@, @"v3"@).
    }
    deriving stock (Eq, Show)

{- | One validator entry inside a 'Blueprint'. A validator may bind a
datum schema, a redeemer schema, both, or neither. The @title@ — when
present — is used by 'BlueprintArgumentSelector' to disambiguate
between validators that share a parameter shape.
-}
data BlueprintValidator = BlueprintValidator
    { validatorTitle :: Maybe Text
    -- ^ Validator-scoped title (often @"spend"@, @"mint"@, etc.). Absent
    -- when the blueprint author left the @title@ field unset.
    , validatorDatum :: Maybe BlueprintArgument
    -- ^ Schema for the datum argument of a spending validator, if any.
    , validatorRedeemer :: Maybe BlueprintArgument
    -- ^ Schema for the redeemer argument of any validator kind, if any.
    }
    deriving stock (Eq, Show)

{- | A single typed argument bound to a 'BlueprintValidator'. The schema
is the local view (it can still carry 'SchemaReference' edges into the
surrounding 'blueprintDefinitions'); the title — if present — is the
semantic name the author attached to that argument and is used as the
top-level field name when an outer @SchemaConstructor@ wraps it.
-}
data BlueprintArgument = BlueprintArgument
    { argumentTitle :: Maybe Text
    -- ^ Operator-supplied name for the argument (e.g. @"redeemer"@,
    -- @"orderDatum"@). Absent when the blueprint author left it unset.
    , argumentSchema :: BlueprintSchema
    -- ^ The structural schema describing the argument's
    -- @PlutusCore.Data@ shape.
    }
    deriving stock (Eq, Show)

{- | Selects whether 'BlueprintArgumentSelector' targets the datum or the
redeemer slot of a validator.
-}
data BlueprintArgumentKind
    = -- | Match the validator's @datum@ argument.
      BlueprintDatum
    | -- | Match the validator's @redeemer@ argument.
      BlueprintRedeemer
    deriving stock (Eq, Show)

{- | Cross-blueprint argument selector: an optional validator title plus
a 'BlueprintArgumentKind'. When 'selectorValidatorTitle' is 'Nothing',
every validator of every blueprint is a candidate; when 'Just', only
validators whose 'validatorTitle' matches contribute.
-}
data BlueprintArgumentSelector = BlueprintArgumentSelector
    { selectorValidatorTitle :: Maybe Text
    -- ^ Validator-title filter applied during selection. 'Nothing' means
    -- "any title accepted".
    , selectorArgumentKind :: BlueprintArgumentKind
    -- ^ Which argument slot (datum or redeemer) to match.
    }
    deriving stock (Eq, Show)

{- | Structural errors that can surface when looking up a typed argument
against a list of 'Blueprint's, before any 'Data' decoding takes
place.
-}
data BlueprintMatchError
    = -- | The selector matched no validator argument across the provided
      -- blueprints.
      BlueprintArgumentMissing
    | -- | More than one validator argument matched the selector; the
      -- list carries the candidate labels for the operator-facing
      -- diagnostic.
      BlueprintArgumentAmbiguous [Text]
    | -- | A 'SchemaReference' pointed at a name absent from
      -- 'blueprintDefinitions'.
      BlueprintDefinitionMissing Text
    | -- | A 'SchemaReference' loop was detected while resolving (the
      -- definition refers to itself directly or transitively). The
      -- reference name that closes the cycle is carried.
      BlueprintDefinitionCycle Text
    deriving stock (Eq, Show)

{- | Open, schema-driven projection of a 'PlutusCore.Data' value. Every
constructor name and field key is taken from the matched
'BlueprintSchema' (constructors become @OpenObject@ records, fields
become string-typed keys), so the surrounding emitter can build typed
predicate IRIs without re-walking the schema. @OpenBytes@ holds the
raw bytes hex-encoded for ASCII-clean rendering.
-}
data OpenValue
    = -- | A constructor or map entry as a string-keyed record.
      OpenObject (Map Text OpenValue)
    | -- | A list of values — either positional (from 'SchemaList' /
      -- 'SchemaListOf') or map entries lifted as @{key,value}@ records
      -- (from 'SchemaMap').
      OpenArray [OpenValue]
    | -- | An integer literal.
      OpenInteger Integer
    | -- | A UTF-8 text literal (only produced through 'OpenBytes' today;
      -- reserved for future Plutus-side text types).
      OpenText Text
    | -- | Raw bytes rendered as lowercase hex. The hex normalisation is
      -- intentional: downstream RDF emitters can drop this directly into
      -- @cardano:bytesHex@ literals.
      OpenBytes Text
    deriving stock (Eq, Show)

{- | Structural errors raised by 'decodeBlueprintData' when a Plutus
@Data@ value does not conform to the supplied 'BlueprintSchema'. None
of these are recoverable inside the decoder itself; the caller may
choose to skip the typed branch and fall back to raw bytes.
-}
data BlueprintDataError
    = -- | The 'Data' constructor did not match the schema's expected
      -- shape (e.g. @PLC.B@ found where 'SchemaInteger' was declared).
      -- The 'Text' is the schema kind name for diagnostics.
      BlueprintDataTypeMismatch Text
    | -- | The encountered 'PLC.Constr' tag differs from the schema's
      -- declared constructor index.
      BlueprintConstructorMismatch
        { expectedConstructorIndex :: Integer
        , actualConstructorIndex :: Integer
        }
    | -- | The encountered 'PLC.Constr' (or @PLC.List@ under
      -- 'SchemaList') has a field count that disagrees with the
      -- schema's declaration.
      BlueprintFieldCountMismatch
        { expectedFieldCount :: Int
        , actualFieldCount :: Int
        }
    | -- | A 'SchemaReference' survived all the way to the decoder
      -- without being resolved through 'resolveBlueprintSchema'. The
      -- reference name is carried for the diagnostic.
      BlueprintUnresolvedReference Text
    deriving stock (Eq, Show)

{- | A typed CIP-0057 schema node: an optional semantic title plus the
structural kind. The title — when present — is used as the field name
in 'OpenObject' projections; when absent the field falls back to
@"field\<index\>"@.
-}
data BlueprintSchema = BlueprintSchema
    { schemaTitle :: Maybe Text
    -- ^ Operator-supplied field title; defines how the field will be
    -- named in 'OpenValue' projections when embedded in a record.
    , schemaKind :: BlueprintSchemaKind
    -- ^ Structural shape of the value this schema describes.
    }
    deriving stock (Eq, Show)

{- | Structural sum of the CIP-0057 schema kinds this library
understands. Anything outside this set (e.g. abstract type unions
without a concrete @anyOf@ branching, value-only @const@ fields)
falls through to 'SchemaData' so the surrounding decoder still has a
usable terminal.
-}
data BlueprintSchemaKind
    = -- | A Plutus integer.
      SchemaInteger
    | -- | A Plutus bytestring.
      SchemaBytes
    | -- | A constructor with a fixed index and ordered field schemas.
      SchemaConstructor Integer [BlueprintSchema]
    | -- | A disjunction of alternative schemas — the decoder accepts
      -- the unique one that decodes cleanly (and reports
      -- 'BlueprintDataTypeMismatch' if zero or several do).
      SchemaAnyOf [BlueprintSchema]
    | -- | A tuple-shaped list with fixed positional schemas, one per
      -- element.
      SchemaList [BlueprintSchema]
    | -- | A homogenous list where every element shares the same
      -- element schema.
      SchemaListOf BlueprintSchema
    | -- | CIP-57 @"dataType": "map"@ — a Plutus 'PLC.Map' payload whose keys
      -- match the first sub-schema and values the second. Decodes as
      -- @OpenArray [OpenObject {"key" -> k, "value" -> v}, ...]@ so the
      -- typed-emit walker treats each entry as a named-field record.
      SchemaMap BlueprintSchema BlueprintSchema
    | -- | An opaque @data@ leaf — the decoder produces a generic
      -- 'OpenValue' projection of the Plutus @Data@ AST without
      -- per-field typing.
      SchemaData
    | -- | A reference to a named entry in 'blueprintDefinitions'.
      -- Resolved at the call site by 'resolveBlueprintSchema'.
      SchemaReference Text
    deriving stock (Eq, Show)

{- | Parse a 'Blueprint' from a lazy JSON byte string. The parser
accepts the CIP-0057 subset documented in the module header; anything
outside that subset yields a 'Left' with a structural decoder error
message.

==== __Example__

A minimal blueprint with one validator and one integer-typed datum:

>>> :set -XOverloadedStrings
>>> let blob = "{\"preamble\":{\"title\":\"demo\",\"plutusVersion\":\"v3\"},\"validators\":[{\"title\":\"spend\",\"datum\":{\"schema\":{\"dataType\":\"integer\"}}}]}"
>>> fmap (preambleTitle . blueprintPreamble) (parseBlueprintJSON blob)
Right "demo"

Malformed JSON returns the aeson-level diagnostic via 'Left':

>>> case parseBlueprintJSON "not json" of { Left e -> take 10 e ; Right _ -> "" }
"Unexpected"
-}
parseBlueprintJSON :: LBS.ByteString -> Either String Blueprint
parseBlueprintJSON =
    eitherDecode

{- | High-level cross-blueprint decode: select the unique validator
argument matching the 'BlueprintArgumentSelector' and decode the
supplied 'Data' against it. Returns 'Left' with a human-readable
diagnostic on selection or decode failure, and 'Right' with the
typed projection on success. The 'Text' diagnostic is suitable for
forwarding into an @rdfs:comment@ on a fallback @cardano:Datum@
block.
-}
decodeMatchingBlueprintArgument ::
    [Blueprint] ->
    BlueprintArgumentSelector ->
    Data ConwayEra ->
    Either Text OpenValue
decodeMatchingBlueprintArgument blueprints selector datum =
    case matches of
        [] ->
            Left (Text.pack (show BlueprintArgumentMissing))
        _ ->
            case decodedMatches of
                [(_, value)] ->
                    Right value
                [] ->
                    Left (Text.intercalate "; " failedMatches)
                multiple ->
                    Left $
                        Text.pack $
                            show $
                                BlueprintArgumentAmbiguous (map fst multiple)
  where
    matches =
        matchingArguments blueprints selector
    attempts =
        [ ( matchLabel blueprint validator
          , case resolveBlueprintSchema blueprint (argumentSchema argument) of
                Left err ->
                    Left (Text.pack (show err))
                Right schema ->
                    case decodeBlueprintData schema datum of
                        Left err ->
                            Left (Text.pack (show err))
                        Right value ->
                            Right value
          )
        | (blueprint, validator, argument) <- matches
        ]
    decodedMatches =
        [ (label, value)
        | (label, Right value) <- attempts
        ]
    failedMatches =
        [ label <> ": " <> reason
        | (label, Left reason) <- attempts
        ]

{- | Decode a single 'Data' value against a fully-resolved
'BlueprintSchema'. Use 'resolveBlueprintSchema' first to flatten any
'SchemaReference' edges; passing an unresolved schema reports
'BlueprintUnresolvedReference'.
-}
decodeBlueprintData ::
    BlueprintSchema -> Data ConwayEra -> Either BlueprintDataError OpenValue
decodeBlueprintData schema (Data value) =
    decodeBlueprintValue schema value

decodeBlueprintValue ::
    BlueprintSchema -> PLC.Data -> Either BlueprintDataError OpenValue
decodeBlueprintValue schema value =
    case schemaKind schema of
        SchemaInteger ->
            case value of
                PLC.I integer ->
                    Right (OpenInteger integer)
                _ ->
                    Left (BlueprintDataTypeMismatch "integer")
        SchemaBytes ->
            case value of
                PLC.B bytes ->
                    Right (OpenBytes (hexText bytes))
                _ ->
                    Left (BlueprintDataTypeMismatch "bytes")
        SchemaConstructor expectedIndex fields ->
            case value of
                PLC.Constr actualIndex values
                    | actualIndex /= expectedIndex ->
                        Left
                            BlueprintConstructorMismatch
                                { expectedConstructorIndex = expectedIndex
                                , actualConstructorIndex = actualIndex
                                }
                    | length fields /= length values ->
                        Left
                            BlueprintFieldCountMismatch
                                { expectedFieldCount = length fields
                                , actualFieldCount = length values
                                }
                    | otherwise ->
                        OpenObject . Map.fromList
                            <$> traverse
                                decodeField
                                (zip [0 :: Int ..] (zip fields values))
                _ ->
                    Left (BlueprintDataTypeMismatch "constructor")
        SchemaAnyOf alternatives ->
            decodeAnyOf alternatives value
        SchemaList fields ->
            case value of
                PLC.List values
                    | length fields /= length values ->
                        Left
                            BlueprintFieldCountMismatch
                                { expectedFieldCount = length fields
                                , actualFieldCount = length values
                                }
                    | otherwise ->
                        OpenArray
                            <$> traverse
                                (uncurry decodeBlueprintValue)
                                (zip fields values)
                _ ->
                    Left (BlueprintDataTypeMismatch "list")
        SchemaListOf item ->
            case value of
                PLC.List values ->
                    OpenArray <$> traverse (decodeBlueprintValue item) values
                _ ->
                    Left (BlueprintDataTypeMismatch "list")
        SchemaMap keySchema valueSchema ->
            case value of
                PLC.Map entries ->
                    OpenArray
                        <$> traverse (decodeMapEntry keySchema valueSchema) entries
                _ ->
                    Left (BlueprintDataTypeMismatch "map")
        SchemaData ->
            Right (plutusDataOpenValue value)
        SchemaReference reference ->
            Left (BlueprintUnresolvedReference reference)
  where
    decodeField (index, (fieldSchema, fieldValue)) = do
        decodedValue <- decodeBlueprintValue fieldSchema fieldValue
        pure (fieldName index fieldSchema, decodedValue)
    decodeMapEntry kSchema vSchema (k, v) = do
        decodedKey <- decodeBlueprintValue kSchema k
        decodedValue <- decodeBlueprintValue vSchema v
        pure $
            OpenObject $
                Map.fromList
                    [ ("key", decodedKey)
                    , ("value", decodedValue)
                    ]

decodeAnyOf ::
    [BlueprintSchema] -> PLC.Data -> Either BlueprintDataError OpenValue
decodeAnyOf alternatives value =
    case successes of
        [decoded] ->
            Right decoded
        [] ->
            case alternatives of
                firstAlternative : _ ->
                    decodeBlueprintValue firstAlternative value
                [] ->
                    Left (BlueprintDataTypeMismatch "anyOf")
        _ ->
            Left (BlueprintDataTypeMismatch "ambiguous anyOf")
  where
    successes =
        [ decoded
        | alternative <- alternatives
        , Right decoded <- [decodeBlueprintValue alternative value]
        ]

plutusDataOpenValue :: PLC.Data -> OpenValue
plutusDataOpenValue (PLC.I integer) =
    OpenInteger integer
plutusDataOpenValue (PLC.B bytes) =
    OpenBytes (hexText bytes)
plutusDataOpenValue (PLC.List values) =
    OpenArray (map plutusDataOpenValue values)
plutusDataOpenValue (PLC.Map entries) =
    OpenArray
        [ OpenObject $
            Map.fromList
                [ ("key", plutusDataOpenValue key)
                , ("value", plutusDataOpenValue itemValue)
                ]
        | (key, itemValue) <- entries
        ]
plutusDataOpenValue (PLC.Constr index fields) =
    OpenObject $
        Map.fromList
            [ ("constructor", OpenInteger index)
            , ("fields", OpenArray (map plutusDataOpenValue fields))
            ]

fieldName :: Int -> BlueprintSchema -> Text
fieldName index schema =
    case schemaTitle schema of
        Just title ->
            title
        Nothing ->
            "field" <> Text.pack (show index)

hexText :: BS.ByteString -> Text
hexText =
    TextEncoding.decodeUtf8 . Base16.encode

{- | Resolve a typed 'BlueprintArgumentSelector' against a set of
blueprints to its concrete 'BlueprintSchema'. Returns
'BlueprintArgumentMissing' / 'BlueprintArgumentAmbiguous' on
selection failure and 'BlueprintDefinitionMissing' /
'BlueprintDefinitionCycle' on reference-resolution failure.
-}
matchBlueprintArgument ::
    [Blueprint] ->
    BlueprintArgumentSelector ->
    Either BlueprintMatchError BlueprintSchema
matchBlueprintArgument blueprints selector =
    case matchingArguments blueprints selector of
        [] ->
            Left BlueprintArgumentMissing
        [(blueprint, _, argument)] ->
            resolveBlueprintSchema blueprint (argumentSchema argument)
        matches ->
            Left $
                BlueprintArgumentAmbiguous
                    [ matchLabel blueprint validator
                    | (blueprint, validator, _) <- matches
                    ]

matchingArguments ::
    [Blueprint] ->
    BlueprintArgumentSelector ->
    [(Blueprint, BlueprintValidator, BlueprintArgument)]
matchingArguments blueprints selector =
    [ (blueprint, validator, argument)
    | blueprint <- blueprints
    , validator <- blueprintValidators blueprint
    , validatorMatches selector validator
    , Just argument <- [selectedArgument selector validator]
    ]

validatorMatches ::
    BlueprintArgumentSelector -> BlueprintValidator -> Bool
validatorMatches selector validator =
    case selectorValidatorTitle selector of
        Nothing ->
            True
        Just title ->
            validatorTitle validator == Just title

selectedArgument ::
    BlueprintArgumentSelector -> BlueprintValidator -> Maybe BlueprintArgument
selectedArgument selector =
    case selectorArgumentKind selector of
        BlueprintDatum ->
            validatorDatum
        BlueprintRedeemer ->
            validatorRedeemer

matchLabel :: Blueprint -> BlueprintValidator -> Text
matchLabel blueprint validator =
    case validatorTitle validator of
        Just title ->
            title
        Nothing ->
            preambleTitle (blueprintPreamble blueprint)

{- | Flatten a 'BlueprintSchema' against a single 'Blueprint''s
definitions table by recursively resolving 'SchemaReference' nodes.
Cyclic references (self-referential definitions, which CIP-0057
allows for things like SundaeSwap's @MultisigScript@) degrade to
'SchemaData' at the cycle boundary so surrounding non-recursive
fields can still decode typed. Returns 'BlueprintDefinitionMissing'
when a reference name is not in the table.
-}
resolveBlueprintSchema ::
    Blueprint -> BlueprintSchema -> Either BlueprintMatchError BlueprintSchema
resolveBlueprintSchema blueprint =
    go Set.empty
  where
    go seen schema =
        case schemaKind schema of
            SchemaReference reference
                | reference `Set.member` seen ->
                    -- A reference loop in the blueprint definitions
                    -- (e.g. SundaeSwap @MultisigScript@'s self-recursive
                    -- @AllOf | AnyOf@ alternatives) cannot be resolved
                    -- eagerly without diverging. Degrading the cyclic
                    -- subtree to 'SchemaData' lets the surrounding
                    -- (non-recursive) record fields still decode typed
                    -- while the recursive payload appears as the
                    -- 'plutusDataOpenValue' AST. Phase 4 (#66) of the
                    -- SHACL-shapes work depends on this for Sundae
                    -- @OrderDatum.destination@ typing.
                    Right (BlueprintSchema (schemaTitle schema) SchemaData)
                | otherwise ->
                    case Map.lookup reference (blueprintDefinitions blueprint) of
                        Nothing ->
                            Left (BlueprintDefinitionMissing reference)
                        Just definition ->
                            -- A constructor field can attach a semantic title
                            -- (e.g. @"recipient"@) at the outer schema node and
                            -- nest the @$ref@ inside a @"schema"@ wrapper. When
                            -- following the @$ref@, keep the outer title — it
                            -- names the field through to 'decodeBlueprintValue'
                            -- and pins the typed predicate
                            -- (@:SwapOrder_recipient@ vs the definition title
                            -- @:SwapOrder_Credential@). T103 / A-001
                            -- correction-in-passing alongside the field-wrapper
                            -- parser fix.
                            let inheritedTitle =
                                    case schemaTitle schema of
                                        Just _ -> schemaTitle schema
                                        Nothing -> schemaTitle definition
                                titled =
                                    definition{schemaTitle = inheritedTitle}
                             in go (Set.insert reference seen) titled
            SchemaConstructor index fields ->
                BlueprintSchema (schemaTitle schema)
                    . SchemaConstructor index
                    <$> traverse (go seen) fields
            SchemaAnyOf alternatives ->
                BlueprintSchema (schemaTitle schema)
                    . SchemaAnyOf
                    <$> traverse (go seen) alternatives
            SchemaList fields ->
                BlueprintSchema (schemaTitle schema)
                    . SchemaList
                    <$> traverse (go seen) fields
            SchemaListOf item ->
                BlueprintSchema (schemaTitle schema)
                    . SchemaListOf
                    <$> go seen item
            SchemaMap keySchema valueSchema ->
                BlueprintSchema (schemaTitle schema)
                    <$> ( SchemaMap
                            <$> go seen keySchema
                            <*> go seen valueSchema
                        )
            SchemaInteger ->
                Right schema
            SchemaBytes ->
                Right schema
            SchemaData ->
                Right schema

instance FromJSON Blueprint where
    parseJSON =
        withObject "Blueprint" $ \value ->
            Blueprint
                <$> value .: "preamble"
                <*> value .:? "validators" .!= []
                <*> parseBlueprintDefinitions value

parseBlueprintDefinitions :: Object -> Parser (Map Text BlueprintSchema)
parseBlueprintDefinitions value = do
    definitions <- value .:? "definitions" .!= KeyMap.empty
    -- Surface parse failures instead of silently dropping the definition.
    -- A dropped definition turns into a downstream
    -- `BlueprintDefinitionMissing` when any `$ref` follows it, which is
    -- invisible to the operator until typed-emit runs against the blueprint
    -- on a real datum / redeemer. Failing at parse time means the
    -- rules-loader surfaces a `BlueprintParseError` immediately.
    Map.fromList <$> traverse parseEntry (KeyMap.toList definitions)
  where
    parseEntry (key, definitionValue) =
        case parseEither parseJSON definitionValue of
            Right schema ->
                pure (Key.toText key, schema)
            Left err ->
                fail
                    ( "blueprint definition "
                        <> Text.unpack (Key.toText key)
                        <> ": "
                        <> err
                    )

instance FromJSON BlueprintPreamble where
    parseJSON =
        withObject "BlueprintPreamble" $ \value ->
            BlueprintPreamble
                <$> value .: "title"
                <*> value .: "plutusVersion"

instance FromJSON BlueprintValidator where
    parseJSON =
        withObject "BlueprintValidator" $ \value ->
            BlueprintValidator
                <$> value .:? "title"
                <*> value .:? "datum"
                <*> value .:? "redeemer"

instance FromJSON BlueprintArgument where
    parseJSON =
        withObject "BlueprintArgument" $ \value ->
            BlueprintArgument
                <$> value .:? "title"
                <*> value .: "schema"

instance FromJSON BlueprintSchema where
    parseJSON =
        withObject "BlueprintSchema" $ \value -> do
            title <- value .:? "title"
            -- CIP-57 lets a constructor field wrap its inner schema under a
            -- @\"schema\"@ key, e.g.
            -- @{ \"title\": \"recipient\", \"schema\": { \"$ref\": \"...\" } }@.
            -- Honour the wrapping by reading the inner schema's kind when the
            -- key is present; the outer field's @\"title\"@ still names the
            -- BlueprintSchema. Without this unwrap a wrapped field decodes as
            -- 'SchemaData' (the no-@dataType@ fallback), which produces a
            -- generic @{ constructor, fields }@ OpenObject and undoes the
            -- typed-emission contract — surfaced by fixture
            -- @12-blueprint-typed@'s SwapOrder.recipient field. T103 / A-001
            -- walker-extension correction-in-passing.
            wrapped <-
                value
                    .:? "schema" ::
                    Parser (Maybe BlueprintSchema)
            kind <- case wrapped of
                Just inner -> pure (schemaKind inner)
                Nothing -> schemaKindFromObject value
            pure
                BlueprintSchema
                    { schemaTitle = title
                    , schemaKind = kind
                    }

schemaKindFromObject ::
    Object -> Parser BlueprintSchemaKind
schemaKindFromObject value = do
    reference <- value .:? "$ref"
    case reference of
        Just ref ->
            SchemaReference <$> definitionReference ref
        Nothing ->
            schemaKindBody value

schemaKindBody :: Object -> Parser BlueprintSchemaKind
schemaKindBody value = do
    alternatives <- value .:? "anyOf"
    case alternatives of
        Just schemas ->
            pure (SchemaAnyOf schemas)
        Nothing -> do
            dataType <- value .:? "dataType"
            case dataType :: Maybe Text of
                Nothing ->
                    pure SchemaData
                Just "integer" ->
                    pure SchemaInteger
                Just "bytes" ->
                    pure SchemaBytes
                Just "constructor" ->
                    SchemaConstructor
                        <$> value .: "index"
                        <*> value .:? "fields" .!= []
                Just "list" ->
                    listSchemaKind value
                Just "map" ->
                    SchemaMap
                        <$> value .: "keys"
                        <*> value .: "values"
                Just unknown ->
                    fail
                        ( "unsupported Plutus blueprint dataType: "
                            <> Text.unpack unknown
                        )

listSchemaKind :: Object -> Parser BlueprintSchemaKind
listSchemaKind value = do
    items <- value .:? "items"
    case items of
        Nothing ->
            pure (SchemaListOf anyDataSchema)
        Just (Aeson.Array itemValues) ->
            SchemaList <$> traverse parseJSON (toList itemValues)
        Just itemValue ->
            SchemaListOf <$> parseJSON itemValue

anyDataSchema :: BlueprintSchema
anyDataSchema =
    BlueprintSchema
        { schemaTitle = Nothing
        , schemaKind = SchemaData
        }

definitionReference :: Text -> Parser Text
definitionReference reference =
    case Text.stripPrefix "#/definitions/" reference of
        Just definition
            | not (Text.null definition) ->
                pure (jsonPointerToken definition)
        _ ->
            fail
                ( "unsupported Plutus blueprint reference: "
                    <> Text.unpack reference
                )

jsonPointerToken :: Text -> Text
jsonPointerToken =
    Text.replace "~0" "~" . Text.replace "~1" "/"
