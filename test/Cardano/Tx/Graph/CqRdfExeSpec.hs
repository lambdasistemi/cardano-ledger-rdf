{- |
Module      : Cardano.Tx.Graph.CqRdfExeSpec
Description : Exe-level smoke tests for cq-rdf subcommands.
License     : Apache-2.0
-}
module Cardano.Tx.Graph.CqRdfExeSpec (spec) where

import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BS8
import Data.ByteString.Lazy qualified as BSL
import Data.List (isInfixOf)
import Data.List qualified as List
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

import Cardano.Ledger.Binary (serialize)
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Core (eraProtVerLow)

import Fixtures.TxGraph.S12BlueprintTyped qualified as S12

spec :: Spec
spec = describe "cq-rdf executable subcommands" $ do
    mCqRdf <- runIO (lookupEnv "CQ_RDF_EXE")
    case mCqRdf of
        Nothing ->
            it "skipped — CQ_RDF_EXE not set" $
                pendingWith "CQ_RDF_EXE is required for exe-level cq-rdf tests."
        Just "" ->
            it "skipped — CQ_RDF_EXE empty" $
                pendingWith "CQ_RDF_EXE is set but empty."
        Just cqRdf -> do
            it "all subcommands expose --help" $ do
                mapM_
                    ( \args -> do
                        (code, _out, _err) <- runExe cqRdf args
                        code `shouldBe` ExitSuccess
                    )
                    [ ["overlay", "--help"]
                    , ["body", "--help"]
                    , ["blueprint", "--help"]
                    , ["metadata", "--help"]
                    , ["shacl", "--help"]
                    ]

            it "overlay byte-equals the legacy overlay-only fixture" $ do
                let rulesPath =
                        "test/fixtures/tx-graph"
                            </> "02-alice-bob-ada"
                            </> "rules.yaml"
                    expectedPath =
                        "test/fixtures/tx-graph"
                            </> "02-alice-bob-ada"
                            </> "expected.entities.ttl"
                expected <- BS.readFile expectedPath
                (code, out, err) <- runExe cqRdf ["overlay", "--in", rulesPath]
                code `shouldBe` ExitSuccess
                err `shouldBe` BS.empty
                out `shouldBe` expected

            it "body emits body-only TTL and does not merge the overlay" $
                withSystemTempDirectory "cq-rdf-body" $ \dir -> do
                    let txPath = dir </> "tx.cbor"
                    BS.writeFile txPath s12CborBytes
                    (code, out, _err) <- runExe cqRdf ["body", txPath]
                    code `shouldBe` ExitSuccess
                    BS8.unpack out
                        `shouldSatisfy` ("# Transaction body." `isInfixOf`)
                    BS8.unpack out
                        `shouldSatisfy` not . ("Operator-declared entities" `isInfixOf`)

            it "blueprint appends typed datum triples idempotently" $
                withSystemTempDirectory "cq-rdf-blueprint" $ \dir -> do
                    let txPath = dir </> "tx.cbor"
                        bpDir = dir </> "blueprints"
                        bpPath = bpDir </> "swap-v2-datum.cip57.json"
                    BS.writeFile txPath s12CborBytes
                    makeBlueprintWithHash bpDir bpPath
                    (bodyCode, bodyTtl, _bodyErr) <- runExe cqRdf ["body", txPath]
                    bodyCode `shouldBe` ExitSuccess
                    (code1, typed1, _err1) <-
                        runExeWithStdin cqRdf ["blueprint", "--blueprints", bpDir] bodyTtl
                    code1 `shouldBe` ExitSuccess
                    BS8.unpack typed1
                        `shouldSatisfy` (":SwapOrder_recipient" `isInfixOf`)
                    (code2, typed2, _err2) <-
                        runExeWithStdin cqRdf ["blueprint", "--blueprints", bpDir] typed1
                    code2 `shouldBe` ExitSuccess
                    typed2 `shouldBe` typed1

            it "metadata appends typed metadata triples idempotently" $ do
                input <-
                    BS.readFile $
                        "test/fixtures/metadata-typed"
                            </> "contingency-1694.input.ttl"
                expected <-
                    BS.readFile $
                        "test/fixtures/metadata-typed"
                            </> "contingency-1694.ttl"
                (code1, typed1, _err1) <-
                    runExeWithStdin
                        cqRdf
                        ["metadata", "--schemas", treasurySchemaDir]
                        input
                code1 `shouldBe` ExitSuccess
                typed1 `shouldBe` expected
                (code2, typed2, _err2) <-
                    runExeWithStdin
                        cqRdf
                        ["metadata", "--schemas", treasurySchemaDir]
                        typed1
                code2 `shouldBe` ExitSuccess
                typed2 `shouldBe` typed1

            it "shacl exits 0 on a pass and non-zero on a planted violation" $
                withSystemTempDirectory "cq-rdf-shacl" $ \dir -> do
                    let shapesDir = dir </> "shapes"
                        shapePath = shapesDir </> "thing.shacl.ttl"
                    createDirectoryIfMissing True shapesDir
                    BS.writeFile shapePath shaclShape
                    (passCode, _passOut, _passErr) <-
                        runExeWithStdin cqRdf ["shacl", "--shapes", shapesDir] shaclPass
                    passCode `shouldBe` ExitSuccess
                    (failCode, _failOut, _failErr) <-
                        runExeWithStdin cqRdf ["shacl", "--shapes", shapesDir] shaclFail
                    failCode `shouldSatisfy` isFailure

makeBlueprintWithHash :: FilePath -> FilePath -> IO ()
makeBlueprintWithHash dir outPath = do
    let sourcePath = "test/fixtures/tx-graph/blueprints/swap-v2-datum.cip57.json"
        needle = "      \"title\": \"amaru.swap.v2.spend\",\n"
        replacement =
            "      \"title\": \"amaru.swap.v2.spend\",\n"
                <> "      \"hash\": \"fa6a58bbe2d0ff05534431c8e2f0ef2cbdc1602a8456e4b13c8f3077\",\n"
    source <- BS8.readFile sourcePath
    createDirectoryIfMissing True dir
    BS8.writeFile outPath (BS8.pack (replaceOnce needle replacement (BS8.unpack source)))

replaceOnce :: String -> String -> String -> String
replaceOnce needle replacement input =
    case splitOnNeedle needle input of
        Nothing -> input
        Just (before, after) -> before <> replacement <> after

splitOnNeedle :: String -> String -> Maybe (String, String)
splitOnNeedle needle = go ""
  where
    go _ [] = Nothing
    go before rest
        | needle `List.isPrefixOf` rest = Just (reverse before, drop (length needle) rest)
    go before (c : rest) = go (c : before) rest

s12CborBytes :: ByteString
s12CborBytes =
    BSL.toStrict (serialize (eraProtVerLow @ConwayEra) S12.tx)

shaclPass :: ByteString
shaclPass =
    "@prefix ex: <https://example.test/> .\n\
    \ex:thing a ex:Thing ; ex:name \"ok\" .\n"

shaclFail :: ByteString
shaclFail =
    "@prefix ex: <https://example.test/> .\n\
    \ex:thing a ex:Thing .\n"

shaclShape :: ByteString
shaclShape =
    "@prefix ex: <https://example.test/> .\n\
    \@prefix sh: <http://www.w3.org/ns/shacl#> .\n\
    \ex:ThingShape a sh:NodeShape ;\n\
    \  sh:targetClass ex:Thing ;\n\
    \  sh:property [ sh:path ex:name ; sh:minCount 1 ; sh:severity sh:Violation ] .\n"

runExe :: FilePath -> [String] -> IO (ExitCode, ByteString, ByteString)
runExe prog args = do
    let cp =
            (proc prog args)
                { std_in = NoStream
                , std_out = CreatePipe
                , std_err = CreatePipe
                }
    withCreateProcess cp $ \_mStdin mStdout mStderr ph ->
        case (mStdout, mStderr) of
            (Just hOut, Just hErr) -> do
                out <- BS.hGetContents hOut
                err <- BS.hGetContents hErr
                hClose hOut
                hClose hErr
                code <- waitForProcess ph
                pure (code, out, err)
            _ -> fail ("runExe: stdout/stderr pipes not created for " <> prog)

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

isFailure :: ExitCode -> Bool
isFailure ExitSuccess = False
isFailure (ExitFailure _) = True

treasurySchemaDir :: FilePath
treasurySchemaDir =
    "docs/case-studies/2026-05-amaru-treasury/schemas"
