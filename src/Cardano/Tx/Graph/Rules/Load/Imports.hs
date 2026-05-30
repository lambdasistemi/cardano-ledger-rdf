{- |
Module      : Cardano.Tx.Graph.Rules.Load.Imports
Description : Operator overlay YAML vocabulary imports.
License     : Apache-2.0

Phase 3 of epic #66 (separate runtime from apps).

An operator's overlay YAML can declare an @imports:@ block listing
non-cardano vocabularies that the overlay uses. Each entry is one of:

* A built-in short name (currently only @treasury@), resolved against
  the registry held in this module.
* An inline object @{iri: \<URL\>, as: \<short-name\>}@ — for
  ontologies that have no built-in registry entry.

The @cardano:@ namespace is always implicit; it does not need to
appear in @imports:@. Cardano-shipped keys
(@from-address@, @script@, @asset@, @pool@, @drep@, @keys@, @bytes@,
@name@, @label@, @of@) live in that namespace.

Treasury-overlay keys (@paid-via@, @role@, @attests@, @ipfs@) are
declared by the @treasury@ vocabulary; using any of them without
@imports: [treasury]@ is a parser error.

When two imported vocabularies declare the same local key
(collision), the parser refuses to guess and demands the operator
write the explicit prefixed form, e.g. @treasury:role:@.

This module owns:

* 'BuiltInRegistry' — the static short-name → IRI table for known
  vocabularies (currently just @treasury@).
* 'ImportEntry' — one parsed entry from the @imports:@ list, AFTER
  the vocab-vs-file disambiguation done by the parser.
* 'Imports' — the assembled name → IRI table the parser uses to
  resolve every YAML key on an entity / attestation / blueprint entry.
* 'KeyResolution' / 'resolveKey' — the per-key lookup, returning
  the resolved namespace IRI or one of the three error variants
  (unknown, ambiguous, missing-import).
* 'cardanoKeys' / 'treasuryKeys' — the canonical key tables per
  vocabulary.
-}
module Cardano.Tx.Graph.Rules.Load.Imports (
    -- * Built-in registry
    builtInRegistry,
    BuiltInRegistry,

    -- * Parsed imports
    ImportEntry (..),
    Imports (..),
    emptyImports,
    addImport,
    importEntryShortName,
    importEntryIri,
    importEntryFromName,

    -- * Constants
    cardanoIri,
    treasuryIri,
    cardanoKeys,
    treasuryKeys,

    -- * Key resolution
    KeyResolution (..),
    resolveKey,
) where

import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)

{- | The static short-name registry. An operator can write a bare
short name in @imports:@ and the loader resolves it through this
table. Unknown short names are an error unless the operator
supplied an explicit @{iri:, as:}@ object.

The registry is intentionally tiny — additional vocabularies are
either declared inline by the operator or added to the registry in
a code change tracked by an issue. This keeps the set of "magic"
names auditable.
-}
type BuiltInRegistry = Map Text Text

-- | The single built-in registry: @treasury@ → 'treasuryIri'.
builtInRegistry :: BuiltInRegistry
builtInRegistry =
    Map.fromList
        [ ("treasury", treasuryIri)
        ]

-- | The implicit cardano namespace IRI.
cardanoIri :: Text
cardanoIri = "https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#"

-- | The treasury overlay namespace IRI.
treasuryIri :: Text
treasuryIri = "https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#"

{- | One parsed @imports:@ vocabulary entry — short name plus the
resolved namespace IRI. The short name is what the operator writes
as a YAML key prefix (@treasury:role@) and what 'resolveKey' uses
to build the per-key namespace lookup.

The parser produces one 'ImportEntry' per non-file entry in
@imports:@. File-style entries (paths ending in @.yaml@ / @.yml@ /
@.ttl@ or containing path separators) are NOT vocab imports; the
parser routes those to the imports resolver instead.
-}
data ImportEntry = ImportEntry
    { importEntryName :: !Text
    -- ^ The short name (the prefix the operator can write in
    -- @treasury:role:@-style explicit keys).
    , importEntryNamespace :: !Text
    -- ^ The resolved namespace IRI (e.g.
    -- @https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#@).
    }
    deriving stock (Eq, Ord, Show)

-- | Resolve a built-in short name → 'ImportEntry'.
importEntryFromName :: Text -> Maybe ImportEntry
importEntryFromName name = do
    iri <- Map.lookup name builtInRegistry
    pure (ImportEntry name iri)

-- | The short name of an import entry (for diagnostic messages).
importEntryShortName :: ImportEntry -> Text
importEntryShortName = importEntryName

-- | The namespace IRI of an import entry.
importEntryIri :: ImportEntry -> Text
importEntryIri = importEntryNamespace

{- | The assembled vocabulary table the parser consults when
resolving every YAML key on an entity / attestation / blueprint
entry. Built from the implicit @cardano@ entry plus each parsed
@imports:@ entry.

The 'importsKnown' field carries the ordered list of imports
exactly as resolved (cardano never appears here — it is implicit).
The emitter walks this list to mint the @owl:imports@ triples at
the top of the overlay TTL.

The 'importsKeyTable' is a derived view: for each local key name,
the list of namespace IRIs that claim it. A key with a single-element
list resolves unambiguously; a list with multiple elements is a
collision that demands an explicit @prefix:key:@ form.
-}
data Imports = Imports
    { importsKnown :: ![ImportEntry]
    -- ^ Vocab imports declared by the operator, in source order.
    -- Does NOT include the implicit cardano entry.
    , importsKeyTable :: !(Map Text [ImportEntry])
    -- ^ For each local key name, the imports (cardano + declared)
    -- that own a key with that name. Built from 'cardanoKeys',
    -- 'treasuryKeys', and (for inline entries) an empty key list
    -- so the operator MUST use the explicit @prefix:key:@ form for
    -- inline-declared ontologies (the loader has no schema for them).
    }
    deriving stock (Eq, Show)

-- | The empty imports table (cardano implicit, nothing else).
emptyImports :: Imports
emptyImports =
    Imports
        { importsKnown = []
        , importsKeyTable = ownerTable cardanoOwner (Set.toList cardanoKeys)
        }
  where
    cardanoOwner = ImportEntry "cardano" cardanoIri

{- | Extend an existing 'Imports' with one additional vocab import.
Updates 'importsKnown' and refreshes 'importsKeyTable' so the new
import's keys participate in collision detection.

Adding the same short name twice is idempotent — the second add
is a no-op so authors who duplicate @imports:@ entries (e.g. via
file-level concat) do not get spurious collisions.
-}
addImport :: ImportEntry -> Imports -> Imports
addImport entry imports
    | alreadyKnown = imports
    | otherwise =
        let newOwners = ownerKeysFor entry
            mergedTable =
                Map.unionWith (<>) (importsKeyTable imports) newOwners
         in imports
                { importsKnown = importsKnown imports <> [entry]
                , importsKeyTable = mergedTable
                }
  where
    alreadyKnown =
        any
            ((== importEntryName entry) . importEntryName)
            (importsKnown imports)

{- | Per-import key table. For the built-in @cardano@ and @treasury@
imports we know the keys statically; for an inline ontology imported
via @{iri:, as:}@ we have no schema so we publish an empty key set,
which means the operator must use the explicit @prefix:key:@ form
for any key from that ontology.
-}
ownerKeysFor :: ImportEntry -> Map Text [ImportEntry]
ownerKeysFor entry
    | importEntryName entry == "cardano" = ownerTable entry (Set.toList cardanoKeys)
    | importEntryName entry == "treasury" = ownerTable entry (Set.toList treasuryKeys)
    | otherwise = Map.empty

ownerTable :: ImportEntry -> [Text] -> Map Text [ImportEntry]
ownerTable entry keys = Map.fromList [(k, [entry]) | k <- keys]

{- | Cardano-shipped key names that are always available, with or
without any @imports:@ entry. These cover the on-chain entity shapes
plus the universal @name:@ / @label:@ keys and the @of:@ slug
reference used inside attestations.
-}
cardanoKeys :: Set Text
cardanoKeys =
    Set.fromList
        [ "name"
        , "label"
        , "from-address"
        , "script"
        , "asset"
        , "pool"
        , "drep"
        , "keys"
        , "bytes"
        , "policy"
        , "of"
        ]

{- | Treasury-overlay key names. Each is a parser error unless the
overlay YAML declares @imports: [treasury]@ (or an equivalent
inline import with these key names — currently not supported, since
we have no inline-schema mechanism). The four keys mirror the
predicates Phase 1 moved out of the @cardano:@ namespace.
-}
treasuryKeys :: Set Text
treasuryKeys =
    Set.fromList
        [ "paid-via"
        , "role"
        , "attests"
        , "ipfs"
        ]

{- | The result of looking up one YAML key in an 'Imports' table.

* 'KeyResolved' — the key resolves to a single namespace. The
  parser proceeds with the key's resolved shape.
* 'KeyUnknown' — no import owns this key. The parser surfaces
  @unknown key '<k>'; did you forget to add it to imports:?@.
* 'KeyAmbiguous' — two or more imports own this key. The parser
  surfaces @key '<k>' is ambiguous (imports: <a>, <b>); qualify
  it as '<a>:<k>:' or '<b>:<k>:'@.
* 'KeyMissingImport' — exactly one vocabulary owns this key, but
  it is not in 'importsKnown'. The parser surfaces
  @key '<k>' requires 'imports: [<vocab>]'@.

The fourth variant is the most operator-friendly path for the
common case: the operator wrote @paid-via:@ without
@imports: [treasury]@, and we can hint exactly what is missing.
-}
data KeyResolution
    = KeyResolved !ImportEntry
    | KeyUnknown
    | KeyAmbiguous ![ImportEntry]
    | -- | The short name of the vocab that owns this key.
      KeyMissingImport !Text
    deriving stock (Eq, Show)

{- | Look up a key in the imports table.

The resolution proceeds in order:

1. Check 'importsKeyTable' (which already includes the implicit
   cardano entry) for any import that owns this key.

    * Exactly one owner → 'KeyResolved'.
    * Two or more owners → 'KeyAmbiguous'.

2. If nothing in the table owns this key, check whether it is a
   built-in treasury key — in which case the operator forgot to
   import treasury. Surface 'KeyMissingImport'.

3. Otherwise the key is truly unknown.

The third step keeps the loader from accidentally accepting a key
that happens to match an inline-imported ontology with no schema
declaration — those go through explicit @prefix:key:@ keys only.
-}
resolveKey :: Imports -> Text -> KeyResolution
resolveKey imports key =
    case Map.lookup key (importsKeyTable imports) of
        Just [owner] -> KeyResolved owner
        Just owners@(_ : _ : _) -> KeyAmbiguous owners
        _
            | Set.member key treasuryKeys -> KeyMissingImport "treasury"
            | otherwise -> KeyUnknown
