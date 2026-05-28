{- |
Module      : Cardano.Tx.Graph.Emit.NativeScript
Description : Recursive RDF walker for Conway native scripts.
License     : Apache-2.0

Private emitter helper for native Cardano scripts. It turns the six
Conway CDDL constructors into a recursive RDF tree while keeping the
root script hash join used by reference scripts and witness scripts.
-}
module Cardano.Tx.Graph.Emit.NativeScript (
    emitNativeScriptTree,
) where

import Data.ByteString (ByteString)
import Data.Foldable (toList)
import Data.Text qualified as Text

import Cardano.Crypto.Hash (hashToBytes)
import Cardano.Ledger.Allegra.Scripts (
    pattern RequireTimeExpire,
    pattern RequireTimeStart,
 )
import Cardano.Ledger.BaseTypes (SlotNo (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Core (NativeScript)
import Cardano.Ledger.Hashes (KeyHash (..))
import Cardano.Ledger.Shelley.Scripts (
    pattern RequireAllOf,
    pattern RequireAnyOf,
    pattern RequireMOf,
    pattern RequireSignature,
 )

import Cardano.Tx.Graph.Emit.Lookup (BnodeName (..), LookupTable)
import Cardano.Tx.Graph.Emit.Monad (Emit, tellTriple)
import Cardano.Tx.Graph.Emit.Triple (
    Object (..),
    Predicate (..),
    Subject (..),
    Triple (..),
 )
import Cardano.Tx.Graph.Emit.Vocab (VocabTerm (..), vocabCurie)
import Cardano.Tx.Graph.Rules.Load (LeafType (LtScriptHash, PaymentKey))

{- | Emit a typed native-script tree rooted at the supplied bnode.

The root carries @cardano:hasHash@ so it can join with other script
hash references. Child nodes intentionally omit hash/raw-byte leaves:
their identity is structural and anchored by the parent-derived
@_cN@ bnode name.
-}
emitNativeScriptTree ::
    LookupTable ->
    (LookupTable -> LeafType -> ByteString -> Emit BnodeName) ->
    BnodeName ->
    ByteString ->
    NativeScript ConwayEra ->
    Emit ()
emitNativeScriptTree lookupTbl resolveIdent rootBnode hashBytes script = do
    hashBnode <- resolveIdent lookupTbl LtScriptHash hashBytes
    emitNode rootBnode (Just hashBnode) script
  where
    emitNode ::
        BnodeName ->
        Maybe BnodeName ->
        NativeScript ConwayEra ->
        Emit ()
    emitNode bnode mHashBnode native = do
        let subj = SBnode bnode
        tellType subj TermNativeScript
        case native of
            RequireSignature (KeyHash h) -> do
                tellType subj TermScriptPubkey
                signerBnode <-
                    resolveIdent lookupTbl PaymentKey (hashToBytes h)
                tellTriple
                    ( Triple
                        subj
                        (PIri (vocabCurie TermRequiresSigner))
                        (OBnode signerBnode)
                    )
            RequireAllOf children -> do
                tellType subj TermScriptAll
                emitChildren bnode subj children
            RequireAnyOf children -> do
                tellType subj TermScriptAny
                emitChildren bnode subj children
            RequireMOf required children -> do
                tellType subj TermScriptNofK
                tellTriple
                    ( Triple
                        subj
                        (PIri (vocabCurie TermRequiredCount))
                        (OIntLit (fromIntegral required))
                    )
                emitChildren bnode subj children
            RequireTimeStart (SlotNo slot) -> do
                tellType subj TermInvalidBefore
                tellSlot subj (fromIntegral slot)
            RequireTimeExpire (SlotNo slot) -> do
                tellType subj TermInvalidHereafter
                tellSlot subj (fromIntegral slot)
            _ ->
                error
                    "Cardano.Tx.Graph.Emit.NativeScript: \
                    \unhandled Conway native script constructor"
        case mHashBnode of
            Nothing -> pure ()
            Just hashBnode ->
                tellTriple
                    ( Triple
                        subj
                        (PIri (vocabCurie TermHasHash))
                        (OBnode hashBnode)
                    )

    emitChildren parentBnode parentSubj children =
        mapM_ (emitChild parentBnode parentSubj) $
            zip [1 :: Int ..] (toList children)

    emitChild parentBnode parentSubj (childIx, childScript) = do
        let childBnode = childNativeScriptBnode parentBnode childIx
        tellTriple
            ( Triple
                parentSubj
                (PIri (vocabCurie TermHasChild))
                (OBnode childBnode)
            )
        emitNode childBnode Nothing childScript

tellType :: Subject -> VocabTerm -> Emit ()
tellType subj term =
    tellTriple (Triple subj PRdfType (OIri (vocabCurie term)))

tellSlot :: Subject -> Integer -> Emit ()
tellSlot subj slot =
    tellTriple
        ( Triple
            subj
            (PIri (vocabCurie TermHasSlot))
            (OIntLit slot)
        )

childNativeScriptBnode :: BnodeName -> Int -> BnodeName
childNativeScriptBnode (BnodeName parent) childIx =
    BnodeName $
        parent
            <> "_c"
            <> Text.pack (show childIx)
