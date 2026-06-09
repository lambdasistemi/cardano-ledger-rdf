{- |
Module      : Cardano.Tx.Graph.Emit.VocabTraceabilitySpec
Description : Per-emit namespacing invariant (analyzer H1 / SC-005 / FR-009).
License     : Apache-2.0

Asserts the three vocab-traceability invariants on the joint
Turtle output of every fixture currently enabled in
'Cardano.Tx.Graph.EmitGoldenSpec':

1. The emitter declares only the four known prefixes — @cardano:@,
   @rdf:@, @rdfs:@, fixture-local empty prefix — and no others.
   The @rdf:@ prefix was added at T104 to carry the RDF-list
   primitives ('rdf:first', 'rdf:rest', 'rdf:nil') that bind an
   output's multi-asset value list cells. The @xsd:@ prefix carries
   explicit boolean literals such as @cardano:isValid@.
2. No body line references a prefix outside that set (no
   @ex:foo@, no @owl:Class@, etc. Turtle's @a@ keyword covers
   the bare @rdf:type@ subject-predicate; the @rdf:@ prefix
   surfaces only as the multi-asset list-cell predicates and
   the @rdf:nil@ list terminator).
3. No @_internal:@ substring leaks into the bytes. This catches
   accidental leaks of internal vocabulary draft IRIs.

The traceability spec parses with a regex sweep — full Turtle
parsing is out of scope; the point is per-emit invariant catching.

== Per-A-002 (T007 follow-up)

The rule is "VocabTraceabilitySpec runs over every fixture
GREEN in EmitGoldenSpec", so each new fixture flip in a future
slice should add the fixture to 'enabledFixtures' below. T007
covers 02 + 03 + 04 + 05 + 08; T008 adds 06 + 07; T009 adds 09;
T010 adds 01 + 10 + 11 (11/11 fixtures = 33/33 invariants).
-}
module Cardano.Tx.Graph.Emit.VocabTraceabilitySpec (spec) where

import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BS8
import Data.Char (isAlpha, isAlphaNum)
import Data.List (nub, sort)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import System.FilePath ((</>))

import Cardano.Ledger.Hashes (ScriptHash)
import Cardano.Tx.Blueprint (Blueprint)
import Cardano.Tx.Graph.Emit (
    EmitFormat (..),
    ResolvedUTxO,
    emit,
    serialize,
 )
import Cardano.Tx.Graph.Rules.Load (
    EntityDecl,
    RulesLoadResult (..),
    loadRulesFile,
    rulesBlueprints,
    rulesEntities,
 )
import Cardano.Tx.Ledger (ConwayTx)

import Fixtures.TxGraph.S01_AmaruTreasurySwap qualified as S01
import Fixtures.TxGraph.S02_AliceBobAda qualified as S02
import Fixtures.TxGraph.S03_MultiAssetTransfer qualified as S03
import Fixtures.TxGraph.S04_MintSpendScriptOverlap qualified as S04
import Fixtures.TxGraph.S05_WithdrawalScriptStake qualified as S05
import Fixtures.TxGraph.S06_StakePoolDelegation qualified as S06
import Fixtures.TxGraph.S07_VoteDelegation qualified as S07
import Fixtures.TxGraph.S08_ContingencyDisburse qualified as S08
import Fixtures.TxGraph.S09_MpfsFactsRequest qualified as S09
import Fixtures.TxGraph.S10_GovernanceTreasuryWithdrawal qualified as S10
import Fixtures.TxGraph.S11_AmaruTreasurySwapReal qualified as S11
import Fixtures.TxGraph.S14BlueprintDecodeFail qualified as S14
import Fixtures.TxGraph.S18_NativeScriptNested qualified as S18
import Fixtures.TxGraph.S19_NativeScriptTimelock qualified as S19
import Fixtures.TxGraph.S21_AuxiliaryData qualified as S21
import Fixtures.TxGraph.S22_IsValidFalse qualified as S22
import Fixtures.TxGraph.S23_CertStakeRegistration qualified as S23
import Fixtures.TxGraph.S24_CertDRepAnchors qualified as S24
import Fixtures.TxGraph.S25_CertPoolParams qualified as S25
import Fixtures.TxGraph.S26_CertCommittee qualified as S26
import Fixtures.TxGraph.S27_CurrentTreasuryValue qualified as S27
import Fixtures.TxGraph.S28_Donation qualified as S28
import Fixtures.TxGraph.S29_GovActionParameterChange qualified as S29
import Fixtures.TxGraph.S30_GovActionUpdateCommittee qualified as S30
import Fixtures.TxGraph.S31_GovActionNewConstitution qualified as S31
import Fixtures.TxGraph.S32_GovActionHardForkInitiation qualified as S32
import Fixtures.TxGraph.S33_MetadataScalarMap qualified as S33
import Fixtures.TxGraph.S34_MetadataFaithful qualified as S34
import Fixtures.TxGraph.S35_MetadataContingency1694 qualified as S35
import Fixtures.TxGraph.S36_MetadataEmptyContainers qualified as S36

import Test.Hspec (
    Spec,
    describe,
    it,
    runIO,
    shouldBe,
    shouldSatisfy,
 )

-- | Fixtures GREEN in 'EmitGoldenSpec' at end of T010 (all 11).
enabledFixtures :: [(String, ConwayTx)]
enabledFixtures =
    [ ("01-amaru-treasury-swap", S01.tx)
    , ("02-alice-bob-ada", S02.tx)
    , ("03-multi-asset-transfer", S03.tx)
    , ("04-mint-spend-script-overlap", S04.tx)
    , ("05-withdrawal-script-stake", S05.tx)
    , ("06-stake-pool-delegation", S06.tx)
    , ("07-vote-delegation", S07.tx)
    , ("08-contingency-disburse", S08.tx)
    , ("09-mpfs-facts-request", S09.tx)
    , ("10-governance-treasury-withdrawal", S10.tx)
    , ("11-amaru-treasury-swap-real", S11.tx)
    , ("14-blueprint-decode-fail", S14.tx)
    , ("18-native-script-nested", S18.tx)
    , ("19-native-script-timelock", S19.tx)
    , ("21-auxiliary-data", S21.tx)
    , ("22-isvalid-false", S22.tx)
    , ("23-cert-stake-registration", S23.tx)
    , ("24-cert-drep-anchors", S24.tx)
    , ("25-cert-pool-params", S25.tx)
    , ("26-cert-committee", S26.tx)
    , ("27-current-treasury-value", S27.tx)
    , ("28-donation", S28.tx)
    , ("29-govaction-parameter-change", S29.tx)
    , ("30-govaction-update-committee", S30.tx)
    , ("31-govaction-new-constitution", S31.tx)
    , ("32-govaction-hard-fork-initiation", S32.tx)
    , ("33-metadata-scalar-map", S33.tx)
    , ("34-metadata-faithful", S34.tx)
    , ("35-metadata-contingency-1694", S35.tx)
    , ("36-metadata-empty-containers", S36.tx)
    ]

spec :: Spec
spec =
    describe "Cardano.Tx.Graph.Emit vocab traceability (T005 / H1 closer)" $
        mapM_ fixtureSpec enabledFixtures

fixtureSpec :: (String, ConwayTx) -> Spec
fixtureSpec (slug, tx) = describe slug $ do
    let dir = "test/fixtures/tx-graph" </> slug
        rulesPath = dir </> "rules.yaml"
    (entities, blueprints) <- runIO (loadRulesData rulesPath)
    let bytes = case emit tx emptyUtxo entities blueprints of
            Right g -> serialize Turtle slug g
            Left _ -> BS.empty
    canonicalLocals <- runIO loadCanonicalLocals
    runIO $
        case emit tx emptyUtxo entities blueprints of
            Left err ->
                fail $
                    "VocabTraceabilitySpec setup: "
                        <> slug
                        <> ": emit returned Left "
                        <> show err
            Right _ -> pure ()
    it "declared prefixes ⊆ {cardano, owl, rdf, rdfs, xsd, :}" $ do
        sort (extractDeclaredPrefixes bytes)
            `shouldBe` sort ["", "cardano", "owl", "rdf", "rdfs", "xsd"]
    it "every CURIE prefix in the body is one of the declared six" $ do
        let usedPrefixes = nub (extractUsedPrefixes bytes)
            ok p = p `elem` ["", "cardano", "owl", "rdf", "rdfs", "xsd"]
            bad = filter (not . ok) usedPrefixes
        bad `shouldBe` []
    it "no '_internal:' substring leak" $ do
        BS8.unpack bytes
            `shouldSatisfy` notContaining "_internal:"
    -- STRICT traceability against the OWNED cardano: ontology. Every
    -- @cardano:Foo@ CURIE the emitter writes must trace to a
    -- declaration in 'vocab/cardano/transactions.ttl' — the source of
    -- truth for the namespace since the vocab migrated into this repo
    -- (#19). The legacy vendored kmaps pin under
    -- 'test/fixtures/canonical-vocab/' is orphaned; retiring it +
    -- PINNED.md is tracked by #40 (validation-gate port).
    it "every emitted cardano: CURIE is declared in the owned ontology" $ do
        let emittedLocals = Set.fromList (extractCardanoLocalParts bytes)
            missing =
                Set.toList
                    (emittedLocals `Set.difference` canonicalLocals)
        missing `shouldBe` []

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

emptyUtxo :: ResolvedUTxO
emptyUtxo = Map.empty

loadRulesData ::
    FilePath ->
    IO ([EntityDecl], [(ScriptHash, Blueprint, Text)])
loadRulesData path = do
    result <- loadRulesFile path
    case result of
        Right res -> pure (rulesEntities res, rulesBlueprints res)
        Left err ->
            fail $
                "VocabTraceabilitySpec.loadRulesData: "
                    <> path
                    <> ": "
                    <> show err

{- | Load the set of @cardano:Foo@ local-parts declared in the
owned @cardano:@ ontology (@vocab/cardano/transactions.ttl@) — the
source of truth for the namespace since the vocab migrated into
this repo (#19). Every emitted CURIE must appear in this set.

The parser is a regex sweep over lines beginning with
@cardano:@ — full Turtle parsing is out of scope. Matches any
line that opens a declaration block: @cardano:Foo a rdfs:Class ;@
or @cardano:hasFoo a rdf:Property ;@.
-}
loadCanonicalLocals :: IO (Set String)
loadCanonicalLocals = do
    bs <- BS.readFile "vocab/cardano/transactions.ttl"
    pure (extractDeclaredCardanoLocals bs)

{- | Extract @Foo@ from every @cardano:Foo …@ declaration line in
the canonical pin.
-}
extractDeclaredCardanoLocals :: ByteString -> Set String
extractDeclaredCardanoLocals bs =
    Set.fromList
        [ takeWhile isIdentChar tail_
        | bsLine <- BS8.lines bs
        , let line = BS8.unpack bsLine
        , Just tail_ <- [stripPrefixStr "cardano:" line]
        , first : _ <- [tail_]
        , isAlpha first || first == '_'
        ]

-- | Drop the prefix from a string; 'Nothing' if not a prefix.
stripPrefixStr :: String -> String -> Maybe String
stripPrefixStr p s
    | take (length p) s == p = Just (drop (length p) s)
    | otherwise = Nothing

{- | Extract every @cardano:Foo@ local-part referenced from the
emitted bytes (the body output produced by 'emit'). Excludes
@\@prefix cardano: …@ declaration lines.
-}
extractCardanoLocalParts :: ByteString -> [String]
extractCardanoLocalParts bs =
    concat
        [ scanCardanoLocals line
        | bsLine <- BS8.lines bs
        , let line = stripAngleIris (BS8.unpack bsLine)
        , not ("@prefix" `isPrefixOfStr` line)
        ]
  where
    isPrefixOfStr p s = take (length p) s == p

{- | Scan a single line for @cardano:Foo@ tokens, returning the
@Foo@ local-part. Skips occurrences inside Turtle string
literals.
-}
scanCardanoLocals :: String -> [String]
scanCardanoLocals = go False
  where
    go _ [] = []
    go inString ('"' : rest) = go (not inString) rest
    go True (_ : rest) = go True rest
    go False s@(_ : rest)
        | "cardano:" `isPfx` s =
            let after = drop 8 s
                (local, after') = span isIdentChar after
             in if null local
                    then go False rest
                    else local : go False after'
        | otherwise = go False rest

    isPfx p s = take (length p) s == p

isIdentChar :: Char -> Bool
isIdentChar c = isAlphaNum c || c == '_' || c == '-'

notContaining :: String -> String -> Bool
notContaining needle haystack = not (needle `isInfixOf'` haystack)

isInfixOf' :: String -> String -> Bool
isInfixOf' needle haystack =
    any
        (\i -> take (length needle) (drop i haystack) == needle)
        [0 .. length haystack - length needle]

{- | Extract the prefix name from every @\@prefix NAME: <IRI> .@
declaration. @NAME@ is empty for the default prefix.
-}
extractDeclaredPrefixes :: ByteString -> [String]
extractDeclaredPrefixes bs =
    [ trim (drop (length prefixKeyword) (takeBefore ':' line))
    | bsLine <- BS8.lines bs
    , let line = BS8.unpack bsLine
    , prefixKeyword `isPrefix` line
    ]
  where
    prefixKeyword :: String
    prefixKeyword = "@prefix"
    isPrefix p s = take (length p) s == p
    takeBefore c = takeWhile (/= c)
    trim = dropWhile (== ' ')

{- | Extract the prefix name of every CURIE @prefix:local@ occurrence in
the body (lines that are not @\@prefix …@ declarations). The empty
prefix appears as @:local@; we report that as @""@.
-}
extractUsedPrefixes :: ByteString -> [String]
extractUsedPrefixes bs =
    concat
        [ scanCuries line
        | bsLine <- BS8.lines bs
        , let line = stripAngleIris (BS8.unpack bsLine)
        , not (prefixKeyword `isPrefix` line)
        , not (hashMark `isPrefix` line)
        ]
  where
    prefixKeyword, hashMark :: String
    prefixKeyword = "@prefix"
    hashMark = "#"
    isPrefix p s = take (length p) s == p

{- | Scan a single line for tokens of the form @[A-Za-z_][A-Za-z0-9_-]*:@
or @:@-prefixed local names. Returns the prefix part of each
occurrence (empty for default prefix). Skips Turtle blank-node
references (@_:foo@) and tokens inside string literals.
-}
scanCuries :: String -> [String]
scanCuries = go False
  where
    go _ [] = []
    -- toggle inString on unescaped quote
    go inString ('"' : rest) = go (not inString) rest
    go True (_ : rest) = go True rest
    -- blank-node reference: skip the "_:NAME"
    go False ('_' : ':' : rest) =
        go False (dropName rest)
    -- empty-prefix CURIE: ":local" not preceded by a name char
    go False (':' : rest)
        | startsLocal rest = "" : go False (dropName rest)
        | otherwise = go False rest
    -- named-prefix CURIE
    go False (c : rest)
        | isAlpha c || c == '_' =
            let (name, after) = spanIdent (c : rest)
             in case after of
                    (':' : after')
                        | startsLocal after' ->
                            name : go False (dropName after')
                    _ -> go False after
        | otherwise = go False rest

    spanIdent =
        span (\c -> isAlphaNum c || c == '_' || c == '-')

    startsLocal [] = False
    startsLocal (c : _) = isAlphaNum c || c == '_'

    dropName =
        dropWhile (\c -> isAlphaNum c || c == '_' || c == '-')

{- | Blank out absolute IRI tokens before CURIE scanning. Turtle
IRIs such as @<urn:cardano:id:...>@ contain colon-separated
segments but are not CURIEs and must not be checked against the
declared prefix set or canonical Cardano vocabulary pin.
-}
stripAngleIris :: String -> String
stripAngleIris = go False False
  where
    go _ _ [] = []
    go inString inIri ('"' : rest)
        | not inIri = '"' : go (not inString) False rest
        | otherwise = ' ' : go inString True rest
    go inString False ('<' : rest)
        | not inString = ' ' : go inString True rest
    go inString True ('>' : rest)
        | not inString = ' ' : go inString False rest
    go inString True (_ : rest)
        | not inString = ' ' : go inString True rest
    go inString inIri (c : rest) = c : go inString inIri rest
