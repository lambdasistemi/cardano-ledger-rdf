{- |
Module      : Cardano.Tx.Graph.Rules.Load.Emit.Overlay
Description : Canonical Turtle serializer for the operator-entity overlay.
License     : Apache-2.0

Emits a byte-stable Turtle document containing only the operator-declared
entity overlay (entities + their identifier blank nodes). The byte
shape is pinned by spec FR-012 and FR-013:

* The Phase A prefix declarations (@cardano:@, optional @treasury:@,
  @rdfs:@, fixture base) in that exact order, then a blank line.
* A header comment block (@# Operator-declared entities (from rules.yaml).@).
* For each entity in source order: a four-line @:slug a cardano:Entity@
  block (label + one @cardano:hasIdentifier <urn:...>@ line per
  identifier, two-space indent), then a blank line.
* For each *first-seen* identifier @(leafType, bytesHex)@ pair: a
  three-line identifier IRI block with @leafType@
  and @bytesHex@ literals, two-space indent. Identifiers shared with
  an earlier entity are NOT re-declared.
* A single trailing newline.

The emitter is total over @['EntityDecl']@ — invalid identifiers
(unknown leafType, etc.) are unreachable here because the YAML
compiler upstream rejects them.
-}
module Cardano.Tx.Graph.Rules.Load.Emit.Overlay (
    emitOverlay,
) where

import Cardano.Tx.Graph.Rules.Load.Imports (
    ImportEntry (..),
    cardanoIri,
 )
import Cardano.Tx.Graph.Rules.Load.Naming (
    NamingTable,
    buildNamingTable,
 )
import Cardano.Tx.Graph.Rules.Load.Types (
    Attestation (..),
    EntityDecl (..),
    EntityIdentifier (..),
    LeafType (..),
 )

import Data.ByteString (ByteString)
import Data.Maybe (isJust)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as TextEncoding

{- | Serialize a list of entity declarations into the canonical
Turtle byte stream the byte-diff golden checks against
@expected.entities.ttl@.

The @fixtureSlug@ argument is the fixture-directory basename and
becomes the local part of the default @:@ prefix's base IRI (e.g.
@02-alice-bob-ada@ → prefix
@\<https://lambdasistemi.github.io/cardano-rdf/fixtures/02-alice-bob-ada#\>@).
It is also the manifest local part minted into the @owl:imports@
declaration at the top of the overlay.

The @vocabImports@ argument is the list of vocabularies the operator
declared in @imports:@, parsed and resolved by the YAML compiler.
The emitter mints one @owl:imports@ triple per declared vocab
ontology resource, plus the always-implicit cardano ontology.
-}
emitOverlay :: Text -> [ImportEntry] -> [EntityDecl] -> [Attestation] -> ByteString
emitOverlay fixtureSlug vocabImports entities attestations =
    TextEncoding.encodeUtf8
        (renderDocument fixtureSlug vocabImports entities attestations)

renderDocument ::
    Text -> [ImportEntry] -> [EntityDecl] -> [Attestation] -> Text
renderDocument fixtureSlug vocabImports entities attestations =
    let table = buildNamingTable entities
        includeTreasury =
            needsTreasuryPrefix vocabImports entities attestations
        header = renderHeader fixtureSlug vocabImports includeTreasury
        (entityBlocks, _) = renderEntities table entities Set.empty
        attestBlocks = renderAttestations attestations
     in header <> entityBlocks <> attestBlocks

renderHeader :: Text -> [ImportEntry] -> Bool -> Text
renderHeader fixtureSlug vocabImports includeTreasury =
    prefixBlock
        <> "\n"
        <> manifestBlock
        <> "#\n"
        <> "# Operator-declared entities (from rules.yaml).\n"
        <> "#\n"
        <> "\n"
  where
    prefixBlock =
        "@prefix cardano: <"
            <> cardanoIri
            <> "> .\n"
            <> treasuryPrefix
            <> customPrefixes
            <> "@prefix owl:     <http://www.w3.org/2002/07/owl#> .\n"
            <> "@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .\n"
            <> "@prefix :        <https://lambdasistemi.github.io/cardano-rdf/fixtures/"
            <> fixtureSlug
            <> "#> .\n"
    treasuryPrefix =
        if includeTreasury
            then
                "@prefix treasury: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#> .\n"
            else ""
    customPrefixes =
        Text.concat
            [ "@prefix "
                <> importEntryName e
                <> ": <"
                <> importEntryNamespace e
                <> "> .\n"
            | e <- vocabImports
            , importEntryName e /= "treasury"
            ]

    manifestBlock =
        let manifestIri =
                "https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/manifest/"
                    <> fixtureSlug
                    <> "#"
            ontologyTargets =
                cardanoOntologyIri : map importToOntologyIri allImports
            allImports =
                [treasuryEntry | includeTreasury]
                    <> [e | e <- vocabImports, importEntryName e /= "treasury"]
            treasuryEntry =
                ImportEntry
                    { importEntryName = "treasury"
                    , importEntryNamespace =
                        "https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#"
                    }
            importsTriples =
                Text.intercalate
                    " ,\n              "
                    (map angled ontologyTargets)
         in "<"
                <> manifestIri
                <> ">\n  a owl:Ontology ;\n  owl:imports "
                <> importsTriples
                <> " .\n\n"

angled :: Text -> Text
angled t = "<" <> t <> ">"

cardanoOntologyIri :: Text
cardanoOntologyIri =
    "https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano/transactions"

{- | Map a vocab import to its ontology resource IRI. The two
built-in vocabs have known ontology suffixes; for inline-imported
custom ontologies we have nothing better than the namespace IRI
itself (the operator provided no ontology-resource hint), so we
mint that as the @owl:imports@ target. Operators authoring a
custom ontology should make the namespace and ontology IRIs equal
to avoid surprises.
-}
importToOntologyIri :: ImportEntry -> Text
importToOntologyIri e
    | importEntryName e == "treasury" =
        "https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury/overlay"
    | otherwise = importEntryNamespace e

needsTreasuryPrefix :: [ImportEntry] -> [EntityDecl] -> [Attestation] -> Bool
needsTreasuryPrefix vocabImports entities attestations =
    any ((== "treasury") . importEntryName) vocabImports
        || any entityNeedsTreasury entities
        || not (null attestations)

entityNeedsTreasury :: EntityDecl -> Bool
entityNeedsTreasury EntityDecl{entityIdentifiers, entityRole, entityPaidVia} =
    null entityIdentifiers || isJust entityRole || isJust entityPaidVia

{- | Render every entity block, accumulating the set of identifier
bnodes that have already been declared so the same blank-node block
is not emitted twice when two entities share an identity.
-}
renderEntities ::
    NamingTable -> [EntityDecl] -> Set Text -> (Text, Set Text)
renderEntities _ [] emitted = ("", emitted)
renderEntities table (entity : rest) emitted =
    let (entityText, emitted') = renderEntity table entity emitted
        (restText, emitted'') = renderEntities table rest emitted'
     in (entityText <> restText, emitted'')

renderEntity ::
    NamingTable -> EntityDecl -> Set Text -> (Text, Set Text)
renderEntity
    table
    EntityDecl
        { entityName
        , entitySlug
        , entityIdentifiers
        , entityBech32
        , entityRole
        , entityPaidVia
        }
    emitted =
        let
            -- Issue #105: an entity with no identifier shape is an
            -- off-chain overlay node, emitted as
            -- @treasury:OffChainEntity@ rather than @cardano:Entity@.
            -- The body emitter never matches these against on-chain
            -- credentials; they exist only to anchor accounting
            -- relations (@treasury:paidVia@ + @treasury:role@) and
            -- attestation references.
            entityType = case entityIdentifiers of
                [] -> "treasury:OffChainEntity"
                _ -> "cardano:Entity"
            -- Issue #100: emit @cardano:bech32 "<addr>"@ on the
            -- entity node when the entity was declared via
            -- @from-address:@. Skipped for the other shapes.
            bechLine = case entityBech32 of
                Just b -> "  cardano:bech32 " <> renderLiteral b <> " ;\n"
                Nothing -> ""
            -- Issue #105: free-text role + cross-entity paid-via
            -- pointer. Both optional.
            roleLine = case entityRole of
                Just r -> "  treasury:role " <> renderLiteral r <> " ;\n"
                Nothing -> ""
            paidViaLine = case entityPaidVia of
                Just s -> "  treasury:paidVia :" <> s <> " ;\n"
                Nothing -> ""
            entityHead =
                ":"
                    <> entitySlug
                    <> " a "
                    <> entityType
                    <> " ;\n"
                    <> "  rdfs:label "
                    <> renderLiteral entityName
                    <> " ;\n"
                    <> bechLine
                    <> roleLine
                    <> paidViaLine
            idLines = renderIdentifierLines table entityIdentifiers
            (idBlocksText, emitted') =
                renderEntityIdentifierBlocks table entityIdentifiers emitted
            -- Off-chain entities have an empty 'entityIdentifiers'
            -- list, so 'renderIdentifierLines' produces an empty
            -- continuation. Close the entity block with a final
            -- @.@ instead. The on-chain branch keeps the existing
            -- shape: the last identifier line terminates with @.@.
            closer = case entityIdentifiers of
                [] -> closeHead entityHead
                _ -> entityHead <> idLines
         in
            ( closer <> "\n" <> idBlocksText
            , emitted'
            )

{- | Replace the trailing @ ;\n@ of an entity head with @ .\n@ so an
identifier-less overlay entity terminates legally as a Turtle
statement. Idempotent against shapes that already end in @.@.
-}
closeHead :: Text -> Text
closeHead t = case Text.stripSuffix " ;\n" t of
    Just trimmed -> trimmed <> " .\n"
    Nothing -> t

{- | Render the @cardano:hasIdentifier _:bnode ;@ continuation lines
attached to an entity's head block. The last line ends with @.@; the
others end with @;@. Two-space indent.
-}
renderIdentifierLines :: NamingTable -> [EntityIdentifier] -> Text
renderIdentifierLines _table idents =
    let iris = map renderIdentifierIri idents
        terminators = replicate (length iris - 1) " ;\n" ++ [" .\n"]
        line iri term =
            "  cardano:hasIdentifier <" <> iri <> ">" <> term
     in Text.concat (zipWith line iris terminators)

{- | Render the per-identifier @\\_:bnode a cardano:Identifier@ block
*only* if the bnode has not been seen before. Threads the seen-set
through the entity's identifier list so subsequent identifiers within
the same entity also skip duplicates (in case the entity itself
declares two pairs that resolve to the same first-seen bnode).
-}
renderEntityIdentifierBlocks ::
    NamingTable ->
    [EntityIdentifier] ->
    Set Text ->
    (Text, Set Text)
renderEntityIdentifierBlocks _ [] emitted = ("", emitted)
renderEntityIdentifierBlocks table (ident : rest) emitted =
    let iri = renderIdentifierIri ident
        (thisBlock, emitted') =
            if Set.member iri emitted
                then ("", emitted)
                else (renderIdentifierBlock iri ident, Set.insert iri emitted)
        (restText, emitted'') = renderEntityIdentifierBlocks table rest emitted'
     in (thisBlock <> restText, emitted'')

renderIdentifierBlock :: Text -> EntityIdentifier -> Text
renderIdentifierBlock iri EntityIdentifier{entityIdLeafType, entityIdBytesHex} =
    "<"
        <> iri
        <> "> a cardano:Identifier ;\n"
        <> "  cardano:leafType "
        <> renderLiteral (renderLeafType entityIdLeafType)
        <> " ;\n"
        <> "  cardano:bytesHex "
        <> renderLiteral entityIdBytesHex
        <> " .\n"
        <> "\n"

renderIdentifierIri :: EntityIdentifier -> Text
renderIdentifierIri EntityIdentifier{entityIdLeafType, entityIdBytesHex} =
    "urn:cardano:id:"
        <> renderLeafType entityIdLeafType
        <> ":"
        <> entityIdBytesHex

{- | Render a 'Text' value as a Turtle string literal — wrap in double
quotes; the fixtures' names contain no double quotes or backslashes,
so naive wrapping is byte-safe for the current corpus. (A more
permissive escaper lands once a fixture forces it.)
-}
renderLiteral :: Text -> Text
renderLiteral t = "\"" <> t <> "\""

{- | Render the operator's @attestations:@ block (issue #105). Each
entry becomes an anonymous @treasury:Attestation@-typed bnode
carrying @rdfs:label@, a @treasury:attests :slug@ slug pointer to
the entity it attests to, and a @treasury:ipfs <ipfs://...>@ IRI
to the artefact. Empty input → no output (no preceding header
block, no trailing newline).
-}
renderAttestations :: [Attestation] -> Text
renderAttestations [] = ""
renderAttestations as =
    "#\n"
        <> "# Off-chain attestations (from rules.yaml).\n"
        <> "#\n"
        <> "\n"
        <> Text.concat (map renderAttestation as)

renderAttestation :: Attestation -> Text
renderAttestation
    Attestation{attestationLabel, attestationIpfs, attestationOf} =
        "[] a treasury:Attestation ;\n"
            <> "  rdfs:label "
            <> renderLiteral attestationLabel
            <> " ;\n"
            <> "  treasury:attests :"
            <> attestationOf
            <> " ;\n"
            <> "  treasury:ipfs <"
            <> attestationIpfs
            <> "> .\n"
            <> "\n"

{- | Pin the canonical string form for each 'LeafType' constructor.
This is the literal that appears in @cardano:leafType@ triples and
matches the camelCase tail used by 'roleSuffix' in the naming
algorithm.
-}
renderLeafType :: LeafType -> Text
renderLeafType = \case
    PaymentKey -> "PaymentKey"
    PaymentScript -> "PaymentScript"
    StakeKey -> "StakeKey"
    StakeScript -> "StakeScript"
    AssetClass -> "AssetClass"
    Policy -> "Policy"
    PoolId -> "PoolId"
    DRepKey -> "DRepKey"
    DRepScript -> "DRepScript"
    CommitteeColdKey -> "CommitteeColdKey"
    CommitteeColdScript -> "CommitteeColdScript"
    CommitteeHotKey -> "CommitteeHotKey"
    CommitteeHotScript -> "CommitteeHotScript"
    -- T122c hash leaves started body-walker-only; TxId and
    -- GovActionId are now also accepted through the operator
    -- keys+bytes overlay path.
    LtTxId -> "TxId"
    LtGovActionId -> "GovActionId"
    LtDatumHash -> "DatumHash"
    LtScriptHash -> "ScriptHash"
    LtScriptDataHash -> "ScriptDataHash"
    LtAuxiliaryDataHash -> "AuxiliaryDataHash"
    LtAnchorDataHash -> "AnchorDataHash"
    LtVrfKeyHash -> "VrfKeyHash"
    LtPoolMetadataHash -> "PoolMetadataHash"
