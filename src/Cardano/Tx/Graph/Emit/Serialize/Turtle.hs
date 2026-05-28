{- |
Module      : Cardano.Tx.Graph.Emit.Serialize.Turtle
Description : Canonical Turtle serializer for the joint emit (private).
License     : Apache-2.0

Private submodule of 'Cardano.Tx.Graph.Emit'. Renders an
'EmittedGraph' value (the typed IR the projection walker
produces) to a byte stream that matches the artisan reference
layout pinned by spec plan D5 / research R4:

* a fixed three-prefix declaration block;
* the operator-entity overlay bytes verbatim (already produced by
  the #48 rules loader);
* a @# Transaction body.@ section header;
* per-input + per-output + address-decomposition subject blocks
  separated by uniform @# Input N@ / @# Output N@ / @# Address
  decompositions — payment + stake credential per leaf.@ headers.

The byte shape is locked by fixture 02's @expected.ttl@ once
the regen ships; T006-T010 keep this serializer GREEN as they
extend the projection walker for new leaves.
-}
module Cardano.Tx.Graph.Emit.Serialize.Turtle (
    renderTurtle,
    renderLatticeTurtle,
    scopeBodyBnodes,
) where

import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Builder (Builder)
import Data.ByteString.Builder qualified as Builder
import Data.ByteString.Char8 qualified as BS8
import Data.ByteString.Lazy qualified as BSL
import Data.List (intersperse)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as TextEncoding

import Cardano.Tx.Graph.Emit.Lookup (BnodeName (..))
import Cardano.Tx.Graph.Emit.Triple (
    BodySection (..),
    Object (..),
    Predicate (..),
    Subject (..),
    SubjectBlock (..),
 )
import Cardano.Tx.Graph.Emit.Vocab (
    cardanoPrefix,
    fixturePrefixBase,
    rdfPrefix,
    rdfsPrefix,
    xsdPrefix,
 )

{- | Render the joint Turtle output for a fixture slug + the
emitter's IR.

The structure (research R4):

@
\@prefix cardano: \<…\> .
\@prefix rdfs:    \<…\> .
\@prefix :        \<fixturePrefixBase + slug + \"#\"\> .

<overlay bytes verbatim>

 #
 # Transaction body.
 #

\<_:tx block\>

 #
 # Input N
 #

\<_:input_K block + optional _:resolvedInput_K block\>

 #
 # Output N
 #

\<_:output_K block\>

 #
 # Address decompositions — payment + stake credential per leaf.
 #

\<address blocks…\>
@

The trailing newline is included.
-}
renderTurtle ::
    Text ->
    [(Text, Text)] ->
    ByteString ->
    [BodySection] ->
    ByteString
renderTurtle slug _explicitPrefixes overlayBytes body =
    BSL.toStrict $
        Builder.toLazyByteString $
            mconcat
                [ renderPrefixes slug
                , bsBuilder (stripOverlayPrefixBlock overlayBytes)
                , mconcat (intersperse newline (map renderSection body))
                ]
  where
    bsBuilder = Builder.byteString

{- | Render a canonical merged Turtle lattice.

The merged form keeps one prefix block and one overlay block at the
top, then emits each transaction body under a stable comment header.
Before rendering a transaction, its body IR is scoped so positional
blank nodes become @_:<txid-short>_<name>@ while content-addressed
identifier bnodes stay unchanged.
-}
renderLatticeTurtle ::
    Text ->
    ByteString ->
    [(Text, [BodySection])] ->
    ByteString
renderLatticeTurtle slug overlayBytes txBodies =
    BSL.toStrict $
        Builder.toLazyByteString $
            mconcat
                [ renderPrefixes slug
                , bsBuilder (stripOverlayPrefixBlock overlayBytes)
                , mconcat
                    (intersperse newline (map renderTxBody txBodies))
                ]
  where
    bsBuilder = Builder.byteString

renderTxBody :: (Text, [BodySection]) -> Builder
renderTxBody (txid, body) =
    mconcat
        [ text "# === tx "
        , text txid
        , text " ===\n"
        , mconcat
            ( intersperse
                newline
                (map renderSection (scopeBodyBnodes txid body))
            )
        ]

{- | Scope positional bnodes in a transaction body by tx id.

The tx id is the full lowercase hex id; the emitted bnode prefix uses
its first eight characters. Content-addressed identifier families
(@hash_@ and @cred_@) are left unchanged so separately-emitted files
can still join on them when loaded together.
-}
scopeBodyBnodes :: Text -> [BodySection] -> [BodySection]
scopeBodyBnodes txid =
    map renameSection
  where
    txTag = Text.take 8 txid

    renameSection section@BodySection{sectionBlocks} =
        section{sectionBlocks = map renameBlock sectionBlocks}

    renameBlock block@SubjectBlock{subjectBlockSubject, subjectBlockPredicates} =
        block
            { subjectBlockSubject = renameSubject subjectBlockSubject
            , subjectBlockPredicates =
                map renamePredicateObject subjectBlockPredicates
            }

    renamePredicateObject (p, o) = (p, renameObject o)

    renameSubject = \case
        SBnode name -> SBnode (renameBnode txTag name)
        SIri iri -> SIri iri

    renameObject = \case
        OBnode name -> OBnode (renameBnode txTag name)
        OIri iri -> OIri iri
        OStringLit lit -> OStringLit lit
        OIntLit i -> OIntLit i
        OBoolLit b -> OBoolLit b

renameBnode :: Text -> BnodeName -> BnodeName
renameBnode txTag bn@(BnodeName name)
    | isContentAddressedBnodeName name = bn
    | isAddressDecompositionBnodeName name = bn
    | (txTag <> "_") `Text.isPrefixOf` name = bn
    | otherwise = BnodeName (txTag <> "_" <> name)

{- TECH-DEBT(#26 follow-up): the current IR stores bnode family as
@BnodeName Text@ rather than constructors such as @PositionalBnode@
and @ContentAddressedBnode@. This is still an IR-level transform,
not a serialized Turtle regex, but it must identify the stable
identifier families by their minted name prefixes until the IR grows
an explicit family tag.
-}
isContentAddressedBnodeName :: Text -> Bool
isContentAddressedBnodeName name =
    "hash_" `Text.isPrefixOf` name || "cred_" `Text.isPrefixOf` name

isAddressDecompositionBnodeName :: Text -> Bool
isAddressDecompositionBnodeName name =
    any
        (`Text.isSuffixOf` name)
        ["Addr", "CredPayment", "CredStake"]

{- | Strip the leading @\@prefix …@ block (plus the trailing
blank line) from an overlay byte stream. The loader's overlay
output always starts with the three Phase A prefix declarations;
inlining them under the serializer's own prefix declarations
would duplicate the lines, so we drop the overlay's copy and
keep its body content (the @# Operator-declared entities@
comment + entity subject blocks).

Empty input is passed through unchanged.
-}
stripOverlayPrefixBlock :: ByteString -> ByteString
stripOverlayPrefixBlock bs
    | BS.null bs = bs
    | otherwise =
        let ls = BS8.lines bs
            tail' = dropWhile isPrefixOrEmpty ls
         in BS8.unlines tail'
  where
    isPrefixOrEmpty l =
        BS.null l || "@prefix" `BS.isPrefixOf` l

----------------------------------------------------------------------
-- Prefix declarations
----------------------------------------------------------------------

renderPrefixes :: Text -> Builder
renderPrefixes slug =
    mconcat
        [ prefixLine "cardano:" cardanoPrefix
        , prefixLine "rdf:    " rdfPrefix
        , prefixLine "rdfs:   " rdfsPrefix
        , prefixLine "xsd:    " xsdPrefix
        , prefixLine ":       " (fixturePrefixBase <> slug <> "#")
        , newline
        ]
  where
    prefixLine label iri =
        mconcat
            [ text "@prefix "
            , text label
            , text " <"
            , text iri
            , text "> .\n"
            ]

----------------------------------------------------------------------
-- Sections
----------------------------------------------------------------------

renderSection :: BodySection -> Builder
renderSection BodySection{sectionHeader, sectionBlocks} =
    mconcat
        [ sectionHeaderBuilder sectionHeader
        , mconcat (intersperse newline (map renderBlock sectionBlocks))
        ]

sectionHeaderBuilder :: Text -> Builder
sectionHeaderBuilder header =
    mconcat
        [ text "#\n# "
        , text header
        , text "\n#\n\n"
        ]

----------------------------------------------------------------------
-- Subject blocks
----------------------------------------------------------------------

renderBlock :: SubjectBlock -> Builder
renderBlock SubjectBlock{subjectBlockSubject, subjectBlockPredicates} =
    case subjectBlockPredicates of
        [] -> renderSubject subjectBlockSubject <> text ".\n"
        ((p0, o0) : rest) ->
            mconcat
                [ renderSubject subjectBlockSubject
                , text " "
                , renderPredicateObject p0 o0
                , renderRestPredicateObjects rest
                ]

renderRestPredicateObjects :: [(Predicate, Object)] -> Builder
renderRestPredicateObjects = \case
    [] -> text " .\n"
    [(p, o)] ->
        mconcat
            [ text " ;\n  "
            , renderPredicateObject p o
            , text " .\n"
            ]
    ((p, o) : rest) ->
        mconcat
            [ text " ;\n  "
            , renderPredicateObject p o
            , renderRestPredicateObjects rest
            ]

renderPredicateObject :: Predicate -> Object -> Builder
renderPredicateObject p o =
    renderPredicate p <> text " " <> renderObject o

renderSubject :: Subject -> Builder
renderSubject = \case
    SBnode (BnodeName n) -> text "_:" <> text n
    SIri t -> renderIriToken t

renderPredicate :: Predicate -> Builder
renderPredicate = \case
    PIri t -> text t
    PRdfType -> text "a"

renderObject :: Object -> Builder
renderObject = \case
    OBnode (BnodeName n) -> text "_:" <> text n
    OIri t -> renderIriToken t
    OStringLit s -> text "\"" <> text (escapeTurtleString s) <> text "\""
    OIntLit i -> text (Text.pack (show i))
    OBoolLit b ->
        text "\""
            <> text (if b then "true" else "false")
            <> text "\"^^xsd:boolean"

renderIriToken :: Text -> Builder
renderIriToken t
    | isAbsoluteIri t = text "<" <> text t <> text ">"
    | otherwise = text t

isAbsoluteIri :: Text -> Bool
isAbsoluteIri t =
    "urn:" `Text.isPrefixOf` t
        || "http://" `Text.isPrefixOf` t
        || "https://" `Text.isPrefixOf` t

{- | Escape a Turtle string-literal payload.

Backslash must be escaped before any escape sequences inserted by
the serializer. Turtle also rejects raw newline and carriage-return
characters inside quoted string literals, so keep common control
characters on their short escaped forms.
-}
escapeTurtleString :: Text -> Text
escapeTurtleString = Text.concatMap escapeChar
  where
    escapeChar '\\' = "\\\\"
    escapeChar '"' = "\\\""
    escapeChar '\n' = "\\n"
    escapeChar '\r' = "\\r"
    escapeChar '\t' = "\\t"
    escapeChar c = Text.singleton c

----------------------------------------------------------------------
-- Builder helpers
----------------------------------------------------------------------

text :: Text -> Builder
text = Builder.byteString . TextEncoding.encodeUtf8

newline :: Builder
newline = text "\n"
