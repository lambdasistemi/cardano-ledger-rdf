{- |
Module      : Cardano.Tx.Graph.ShapesAmaruMay2026Spec
Description : Exe-level smoke tests for the Phase 4 SHACL shapes.
License     : Apache-2.0

Phase 4 of epic #66. Exercises `cq-rdf shacl --shapes <dir>` against
the operator-authored shapes shipped in the May 2026 Amaru Treasury
case study folder. Two facets:

* Pass path — a planted-pass fixture with one operator-issued
  Sundae OrderDatum routing to network_compliance plus one declared
  off-chain entity backed by an attestation. `cq-rdf shacl` MUST
  exit 0 and emit an empty report.

* Fail path — the same fixture with the OrderDatum's destination
  payment credential surgically mutated to `deadbeef…` (still 28
  bytes so the shape's literal-equality FILTER triggers).
  `cq-rdf shacl` MUST exit non-zero and the report MUST name the
  source shape.

The fixture is minimal: it carries only the predicates referenced
by the two shapes (self-swap + attested-disbursement). It does not
go through the body emitter; we hand-author the typed turtle so
the test stays hermetic and fast.
-}
module Cardano.Tx.Graph.ShapesAmaruMay2026Spec (spec) where

import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BS8
import Data.List (isInfixOf)
import System.Directory (createDirectoryIfMissing)
import System.Environment (lookupEnv)
import System.Exit (ExitCode (..))
import System.FilePath ((</>))
import System.IO (hClose)
import System.IO.Temp (withSystemTempDirectory)
import System.Process (
    CreateProcess (..),
    StdStream (..),
    proc,
    waitForProcess,
    withCreateProcess,
 )
import Test.Hspec (
    Spec,
    describe,
    it,
    pendingWith,
    runIO,
    shouldBe,
    shouldSatisfy,
 )

spec :: Spec
spec = describe "Amaru Treasury May 2026 SHACL shapes" $ do
    mCqRdf <- runIO (lookupEnv "CQ_RDF_EXE")
    case mCqRdf of
        Nothing ->
            it "skipped — CQ_RDF_EXE not set" $
                pendingWith "CQ_RDF_EXE required for exe-level shape tests."
        Just "" ->
            it "skipped — CQ_RDF_EXE empty" $
                pendingWith "CQ_RDF_EXE is set but empty."
        Just cqRdf -> do
            it "passes on a planted-pass operator-issued lattice" $
                withShapes $ \dir -> do
                    (code, out, _err) <-
                        runExeWithStdin
                            cqRdf
                            ["shacl", "--shapes", dir]
                            plantedPass
                    code `shouldBe` ExitSuccess
                    BS.length out `shouldSatisfy` (< 4096)

            it "fails on a planted self-swap violation" $
                withShapes $ \dir -> do
                    (code, out, _err) <-
                        runExeWithStdin
                            cqRdf
                            ["shacl", "--shapes", dir]
                            plantedSelfSwapViolation
                    code `shouldSatisfy` isFailure
                    BS8.unpack out
                        `shouldSatisfy` ("self-swap" `isInfixOf`)

            it "fails on a missing-attestation violation" $
                withShapes $ \dir -> do
                    (code, out, _err) <-
                        runExeWithStdin
                            cqRdf
                            ["shacl", "--shapes", dir]
                            plantedMissingAttestation
                    code `shouldSatisfy` isFailure
                    BS8.unpack out
                        `shouldSatisfy` ("attested-disbursement" `isInfixOf`)

{- | Materialise the two case-study shape files into a fresh
temporary directory. The shape bytes are embedded as a literal so
the test is hermetic — no dependency on the cwd or on the
relative path to the case-study folder. They are byte-identical to
the shipped @docs/case-studies/2026-05-amaru-treasury/shapes/*.shacl.ttl@
files modulo header comments.
-}
withShapes :: (FilePath -> IO a) -> IO a
withShapes action = withSystemTempDirectory "amaru-may2026-shapes" $ \dir -> do
    createDirectoryIfMissing True dir
    BS.writeFile (dir </> "self-swap.shacl.ttl") selfSwapShape
    BS.writeFile (dir </> "attested-disbursement.shacl.ttl") attestedShape
    action dir

-- | Inline copy of @shapes/self-swap.shacl.ttl@.
selfSwapShape :: ByteString
selfSwapShape =
    BS8.pack . unlines $
        [ "@prefix sh:       <http://www.w3.org/ns/shacl#> ."
        , "@prefix rdfs:     <http://www.w3.org/2000/01/rdf-schema#> ."
        , "@prefix cardano:  <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#> ."
        , "@prefix tx:       <https://lambdasistemi.github.io/cardano-rdf/fixtures/tx#> ."
        , ""
        , "<https://lambdasistemi.github.io/cardano-ledger-rdf/shapes/2026-05-amaru-treasury/self-swap>"
        , "    a sh:NodeShape ;"
        , "    rdfs:label \"Amaru Treasury May 2026 — self-swap invariant\" ;"
        , "    sh:targetSubjectsOf tx:OrderDatum_destination ;"
        , "    sh:sparql ["
        , "        a sh:SPARQLConstraint ;"
        , "        sh:message \"Operator-issued Sundae OrderDatum {?this} has bad destination {?value}.\" ;"
        , "        sh:severity sh:Violation ;"
        , "        sh:select \"\"\""
        , "            PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>"
        , "            PREFIX tx: <https://lambdasistemi.github.io/cardano-rdf/fixtures/tx#>"
        , "            SELECT $this ?value"
        , "            WHERE {"
        , "                ?enclosingTx a cardano:Transaction ;"
        , "                             cardano:hasOutput ?out ."
        , "                ?out cardano:hasDatum $this ."
        , "                ?enclosingTx cardano:hasInput ?in ."
        , "                ?in cardano:fromTxOutRef ?ref ."
        , "                ?ref cardano:hasTxId ?parentIdNode ;"
        , "                     cardano:hasIndex ?pIdx ."
        , "                ?parentTx cardano:hasTxId ?parentIdNode ;"
        , "                          cardano:hasOutput ?parentOut ."
        , "                ?parentOut cardano:hasIndex ?pIdx ;"
        , "                           cardano:atAddress ?parentAddr ."
        , "                ?parentAddr cardano:hasPaymentCredential ?parentPc ."
        , "                ?parentPc cardano:hasIdentifier ?parentIdent ."
        , "                ?parentIdent cardano:bytesHex"
        , "                    \"32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0d\" ."
        , "                $this tx:OrderDatum_destination ?dest ."
        , "                ?dest tx:_0_address ?destAddr ."
        , "                ?destAddr tx:_0_payment_credential ?destPc ."
        , "                ?destPc tx:_0_field0 ?destIdent ."
        , "                ?destIdent cardano:bytesHex ?value ."
        , "                FILTER (?value !="
        , "                    \"32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0d\")"
        , "            }"
        , "        \"\"\" ;"
        , "    ] ."
        ]

-- | Inline copy of @shapes/attested-disbursement.shacl.ttl@.
attestedShape :: ByteString
attestedShape =
    BS8.pack . unlines $
        [ "@prefix sh:       <http://www.w3.org/ns/shacl#> ."
        , "@prefix rdfs:     <http://www.w3.org/2000/01/rdf-schema#> ."
        , "@prefix treasury: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#> ."
        , ""
        , "<https://lambdasistemi.github.io/cardano-ledger-rdf/shapes/2026-05-amaru-treasury/attested-disbursement>"
        , "    a sh:NodeShape ;"
        , "    rdfs:label \"Amaru Treasury May 2026 — attested disbursement\" ;"
        , "    sh:targetSubjectsOf treasury:paidVia ;"
        , "    sh:sparql ["
        , "        a sh:SPARQLConstraint ;"
        , "        sh:message \"Off-chain entity {?this} has paidVia but no attestation.\" ;"
        , "        sh:severity sh:Violation ;"
        , "        sh:select \"\"\""
        , "            PREFIX treasury: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#>"
        , "            SELECT $this"
        , "            WHERE {"
        , "                $this treasury:paidVia ?bridge ."
        , "                FILTER NOT EXISTS {"
        , "                    ?attestation a treasury:Attestation ;"
        , "                                 treasury:attests $this ."
        , "                }"
        , "            }"
        , "        \"\"\" ;"
        , "    ] ."
        ]

isFailure :: ExitCode -> Bool
isFailure ExitSuccess = False
isFailure (ExitFailure _) = True

runExeWithStdin ::
    FilePath -> [String] -> ByteString -> IO (ExitCode, ByteString, ByteString)
runExeWithStdin prog args input = do
    let cp =
            (proc prog args)
                { std_in = CreatePipe
                , std_out = CreatePipe
                , std_err = CreatePipe
                }
    withCreateProcess cp $ \mStdin mStdout mStderr ph ->
        case (mStdin, mStdout, mStderr) of
            (Just hIn, Just hOut, Just hErr) -> do
                BS.hPut hIn input
                hClose hIn
                out <- BS.hGetContents hOut
                err <- BS.hGetContents hErr
                hClose hOut
                hClose hErr
                code <- waitForProcess ph
                pure (code, out, err)
            _ -> fail ("runExeWithStdin: pipes not created for " <> prog)

-- ----------------------------------------------------------------
-- Fixtures
-- ----------------------------------------------------------------

ncHash :: String
ncHash = "32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0d"

{- | Planted-pass lattice:

* One operator-issued tx consumes a network_compliance UTxO and
  emits an OrderDatum whose destination payment credential equals
  network_compliance — self-swap invariant SATISFIED.
* One off-chain entity declared with treasury:paidVia is backed by
  one treasury:Attestation — attested-disbursement invariant
  SATISFIED.
-}
plantedPass :: ByteString
plantedPass =
    latticeWithDestination ncHash <> attestedOverlayPass

{- | Planted-violation: same lattice but with the order's
destination payment credential mutated to `deadbeef…` (28 bytes,
still parseable as a script hash). Should trigger the self-swap
shape.
-}
plantedSelfSwapViolation :: ByteString
plantedSelfSwapViolation =
    latticeWithDestination "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
        <> attestedOverlayPass

-- | Pass on self-swap; FAIL on missing-attestation.
plantedMissingAttestation :: ByteString
plantedMissingAttestation =
    latticeWithDestination ncHash <> attestedOverlayMissingAttest

{- | One operator-issued swap-order tx with one consumed
network_compliance input and one OrderDatum output. The
destination payment credential is the parameter.
-}
latticeWithDestination :: String -> ByteString
latticeWithDestination destHex =
    BS8.pack . unlines $
        [ "@prefix cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#> ."
        , "@prefix tx: <https://lambdasistemi.github.io/cardano-rdf/fixtures/tx#> ."
        , ""
        , "<urn:test:tx:op1> a cardano:Transaction ;"
        , "  cardano:hasInput _:op1in1 ;"
        , "  cardano:hasOutput _:op1out1 ."
        , ""
        , "_:op1in1 cardano:fromTxOutRef _:op1in1Ref ."
        , "_:op1in1Ref cardano:hasTxId <urn:test:id:parentTx> ;"
        , "            cardano:hasIndex 0 ."
        , ""
        , "<urn:test:parent> a cardano:Transaction ;"
        , "  cardano:hasTxId <urn:test:id:parentTx> ;"
        , "  cardano:hasOutput _:parentOut0 ."
        , ""
        , "_:parentOut0 cardano:hasIndex 0 ;"
        , "             cardano:atAddress _:ncAddr ."
        , ""
        , "_:ncAddr cardano:hasPaymentCredential _:ncPC ."
        , "_:ncPC cardano:hasIdentifier <urn:test:id:ncScript> ."
        , "<urn:test:id:ncScript> cardano:bytesHex \"" <> ncHash <> "\" ."
        , ""
        , "_:op1out1 cardano:hasDatum _:op1datum1 ."
        , "_:op1datum1 tx:OrderDatum_destination _:op1dest ."
        , "_:op1dest tx:_0_address _:op1destAddr ."
        , "_:op1destAddr tx:_0_payment_credential _:op1destPC ."
        , "_:op1destPC tx:_0_field0 _:op1destIdent ."
        , "_:op1destIdent cardano:bytesHex \"" <> destHex <> "\" ."
        ]

{- | Overlay with one declared off-chain entity backed by exactly
one attestation. Both shapes pass on this fragment.
-}
attestedOverlayPass :: ByteString
attestedOverlayPass =
    BS8.pack . unlines $
        [ ""
        , "@prefix treasury: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#> ."
        , "@prefix : <urn:test:overlay:> ."
        , ""
        , ":vendorA a treasury:OffChainEntity ;"
        , "  treasury:paidVia :bridge ."
        , ""
        , "[] a treasury:Attestation ;"
        , "  treasury:attests :vendorA ;"
        , "  treasury:ipfs <ipfs://bafyfake1> ."
        ]

{- | Overlay where the declared off-chain entity has NO
attestation. The attested-disbursement shape MUST flag it.
-}
attestedOverlayMissingAttest :: ByteString
attestedOverlayMissingAttest =
    BS8.pack . unlines $
        [ ""
        , "@prefix treasury: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#> ."
        , "@prefix : <urn:test:overlay:> ."
        , ""
        , ":vendorOrphan a treasury:OffChainEntity ;"
        , "  treasury:paidVia :bridge ."
        ]
