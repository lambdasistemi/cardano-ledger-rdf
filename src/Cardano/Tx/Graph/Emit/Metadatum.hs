{- |
Module      : Cardano.Tx.Graph.Emit.Metadatum
Description : Faithful generic decode of the auxiliary-data metadata map (private).
License     : Apache-2.0

Private submodule of 'Cardano.Tx.Graph.Emit'. Walks the Conway
auxiliary-data transaction-metadata map (@Map Word64 Metadatum@)
and emits a faithful, generic @cardano:@ RDF value tree alongside
the existing opaque-CBOR and hash triples (spec 062).

Each top-level label becomes a 'cardano:hasMetadatum' edge from
the auxiliary-data node to a metadatum-entry node carrying the
integer 'cardano:metadataLabel' and a 'cardano:metadatumValue'
edge to the decoded value. Every value is one of the five Cardano
metadatum kinds, each a blank node typed @cardano:MetadatumValue@
plus a kind class:

* @I@   → @cardano:MetaInt@   + @cardano:intValue@   (xsd:integer)
* @B@   → @cardano:MetaBytes@ + @cardano:bytesHex@   (lowercase hex)
* @S@   → @cardano:MetaText@  + @cardano:textValue@  (xsd:string)
* @List@ → @cardano:MetaList@ + ordered @cardano:hasElement@ edges
* @Map@  → @cardano:MetaMap@  + @cardano:hasEntry@ edges

The decode is __faithful__: lists keep their element order and
arity (a chunked text value stays an N-element list — joining is
spec 063's typed pass, not ours), and map keys are full value
nodes, not assumed strings (research D2–D4).

== Determinism (research D5 / FR-007)

Blank-node names are a pure function of the tree path, so the
emitted Turtle is byte-stable across runs. Starting from the
auxiliary-data node base @aux@:

* entry for label @L@        → @aux_md\<L\>@
* that entry's value         → @aux_md\<L\>_v@
* map entry @i@ at value @X@  → @X_e\<i\>@, key @X_e\<i\>k@, value @X_e\<i\>v@
* list element @i@ at @X@     → @X_l\<i\>@, value @X_l\<i\>v@

The serializer prefixes positional blank nodes with the tx-id
short tag, so these names render as @_:\<txtag\>_aux_md\<L\>…@.
Top-level labels are emitted in ascending @Word64@ order; list
elements and map entries in their on-chain order, each stamped
with an explicit 0-based index.
-}
module Cardano.Tx.Graph.Emit.Metadatum (
    emitMetadataMap,
) where

import Data.ByteString (ByteString)
import Data.ByteString.Base16 qualified as Base16
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as TextEncoding
import Data.Word (Word64)

import Cardano.Ledger.Metadata (Metadatum (B, I, List, Map, S))

import Cardano.Tx.Graph.Emit.Lookup (BnodeName (..))
import Cardano.Tx.Graph.Emit.Monad (Emit, tellTriple)
import Cardano.Tx.Graph.Emit.Triple (
    Object (..),
    Predicate (..),
    Subject (..),
    Triple (..),
 )
import Cardano.Tx.Graph.Emit.Vocab (VocabTerm (..), vocabCurie)

{- | Emit the decoded value tree for an auxiliary-data metadata
map, additively from the auxiliary-data node.

@auxBase@ is the auxiliary-data node's blank-node name (used as
the deterministic path root); @auxSubj@ is the same node as a
'Subject' (the source of the @cardano:hasMetadatum@ edges).
Top-level labels are folded in ascending order; an empty map
emits nothing, so a scripts-only auxiliary-data node gains no
metadatum edges (FR-001 / negative contract).
-}
emitMetadataMap :: BnodeName -> Subject -> Map Word64 Metadatum -> Emit ()
emitMetadataMap (BnodeName auxBase) auxSubj =
    mapM_ emitEntry . Map.toAscList
  where
    emitEntry :: (Word64, Metadatum) -> Emit ()
    emitEntry (label, value) = do
        let entryName = auxBase <> "_md" <> tShow label
            entrySubj = SBnode (BnodeName entryName)
        tellTriple
            ( Triple
                auxSubj
                (PIri (vocabCurie TermHasMetadatum))
                (OBnode (BnodeName entryName))
            )
        tellTriple
            ( Triple
                entrySubj
                (PIri (vocabCurie TermMetadataLabel))
                (OIntLit (toInteger label))
            )
        valueObj <- emitValue (BnodeName (entryName <> "_v")) value
        tellTriple
            ( Triple
                entrySubj
                (PIri (vocabCurie TermMetadatumValueProp))
                valueObj
            )

{- | Emit one typed value node for a 'Metadatum', rooted at the
deterministic blank node @base@, and return the node as the
'Object' the caller links to.

Every node is typed @cardano:MetadatumValue@ plus its kind class
so a consumer can match @?v a cardano:MetadatumValue@ regardless
of kind, or branch on the kind (FR-002 / FR-005). The recursion
preserves list arity and map-entry order exactly (FR-003 /
FR-004); nothing is joined or coerced.
-}
emitValue :: BnodeName -> Metadatum -> Emit Object
emitValue base metadatum = do
    let subj = SBnode base
        tt term obj = tellTriple (Triple subj (PIri (vocabCurie term)) obj)
        typeAs term = tellTriple (Triple subj PRdfType (OIri (vocabCurie term)))
    typeAs TermMetadatumValue
    case metadatum of
        I n -> do
            typeAs TermMetaInt
            tt TermIntValue (OIntLit n)
        B bytes -> do
            typeAs TermMetaBytes
            tt TermBytesHex (OStringLit (hexText bytes))
        S text -> do
            typeAs TermMetaText
            tt TermTextValue (OStringLit text)
        List elements -> do
            typeAs TermMetaList
            mapM_ (emitElement base subj) (zip [0 ..] elements)
        Map entries -> do
            typeAs TermMetaMap
            mapM_ (emitMapEntry base subj) (zip [0 ..] entries)
    pure (OBnode base)

{- | Emit one positional element wrapper of a @cardano:MetaList@:
a @cardano:hasElement@ edge from the list node to a wrapper node
carrying the 0-based @cardano:elementIndex@ and a
@cardano:metadatumValue@ edge to the element's own value node.

The wrapper preserves order and arity — every on-chain element
becomes exactly one wrapper, never merged (FR-003 / SC-002).
-}
emitElement :: BnodeName -> Subject -> (Int, Metadatum) -> Emit ()
emitElement (BnodeName base) listSubj (index, element) = do
    let elemName = base <> "_l" <> tShow index
        elemSubj = SBnode (BnodeName elemName)
    tellTriple
        ( Triple
            listSubj
            (PIri (vocabCurie TermHasElement))
            (OBnode (BnodeName elemName))
        )
    tellTriple
        ( Triple
            elemSubj
            (PIri (vocabCurie TermElementIndex))
            (OIntLit (toInteger index))
        )
    valueObj <- emitValue (BnodeName (elemName <> "v")) element
    tellTriple
        ( Triple
            elemSubj
            (PIri (vocabCurie TermMetadatumValueProp))
            valueObj
        )

{- | Emit one key→value pair of a @cardano:MetaMap@: a
@cardano:hasEntry@ edge from the map node to an entry node
carrying the 0-based @cardano:entryIndex@, a @cardano:metaKey@
edge, and a @cardano:metaValue@ edge.

Both the key and the value are full metadatum value nodes — the
key is never assumed to be a string, so an integer- or
byte-keyed map round-trips faithfully (FR-004).
-}
emitMapEntry :: BnodeName -> Subject -> (Int, (Metadatum, Metadatum)) -> Emit ()
emitMapEntry (BnodeName base) mapSubj (index, (key, value)) = do
    let entryName = base <> "_e" <> tShow index
        entrySubj = SBnode (BnodeName entryName)
    tellTriple
        ( Triple
            mapSubj
            (PIri (vocabCurie TermHasEntry))
            (OBnode (BnodeName entryName))
        )
    tellTriple
        ( Triple
            entrySubj
            (PIri (vocabCurie TermEntryIndex))
            (OIntLit (toInteger index))
        )
    keyObj <- emitValue (BnodeName (entryName <> "k")) key
    tellTriple
        (Triple entrySubj (PIri (vocabCurie TermMetaKey)) keyObj)
    valueObj <- emitValue (BnodeName (entryName <> "v")) value
    tellTriple
        (Triple entrySubj (PIri (vocabCurie TermMetaValue)) valueObj)

{- | Lowercase base16 of a byte string, reused for @cardano:bytesHex@
(mirrors 'Cardano.Tx.Graph.Emit.Project.hexText').
-}
hexText :: ByteString -> Text
hexText = TextEncoding.decodeLatin1 . Base16.encode

-- | Render an integral index/label as decimal 'Text' for a blank-node name.
tShow :: (Show a) => a -> Text
tShow = Text.pack . show
