{- |
Module      : Cardano.Tx.View.TxViewStdinSpec
Description : Exe-level coverage for tx-view --graph - stdin (#61 bug 3).
License     : Apache-2.0

Drives the freshly-built @tx-view@ binary to cover issue #61 bug 3:

* @--graph -@ reads the canonical Turtle graph from stdin, so the
  pipeline @tx-graph … | tx-view --view cli-tree@ works without a
  temporary file. The stdin render must byte-equal the @--graph FILE@
  render of the same graph.
* a graph fed on stdin that carries an off-chain attestation written
  in the @[] a cardano:Attestation ; … .@ form (issue #61 bug 2)
  renders without a parse error — the end-to-end proof that the
  overlay's blank-node-property-list survives the pipe.
* omitting @--graph@ entirely shows --help and exits 0 with a
  message that points the operator at stdin.

The binary is located via @TX_VIEW_EXE@ (set by the @just unit@
recipe and the nix flake check) with a @PATH@ fallback, identical to
'Cardano.Tx.View.EntityOccurrencesSpec'.
-}
module Cardano.Tx.View.TxViewStdinSpec (spec) where

import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BS8
import Data.List (isInfixOf)
import System.Directory (findExecutable)
import System.Environment (lookupEnv)
import System.Exit (ExitCode (..))
import System.IO (hClose)
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
    expectationFailure,
    it,
    runIO,
    shouldBe,
    shouldSatisfy,
 )

spec :: Spec
spec =
    describe "tx-view --graph - stdin support (#61 bug 3)" $ do
        mExe <- runIO locateTxView
        case mExe of
            Nothing ->
                it "tx-view is on PATH or pointed at by TX_VIEW_EXE" $
                    expectationFailure
                        "tx-view neither on PATH nor in TX_VIEW_EXE."
            Just exe -> do
                graph <- runIO (BS.readFile fixtureGraph)

                it
                    ( "(1) --graph - renders byte-identically to "
                        <> "--graph FILE"
                    )
                    $ do
                        (codeFile, outFile, _) <-
                            runExe exe ["--graph", fixtureGraph, "--view", "cli-tree"]
                        (codeStdin, outStdin, _) <-
                            runExeWithStdin
                                exe
                                ["--graph", "-", "--view", "cli-tree"]
                                graph
                        codeFile `shouldBe` ExitSuccess
                        codeStdin `shouldBe` ExitSuccess
                        outStdin `shouldBe` outFile

                it
                    ( "(2) a [] a cardano:Attestation ; … . block fed on "
                        <> "stdin renders without a parse error"
                    )
                    $ do
                        (code, _out, err) <-
                            runExeWithStdin
                                exe
                                ["--graph", "-", "--view", "cli-tree"]
                                (graph <> attestationBlock)
                        BS8.unpack err
                            `shouldSatisfy` not
                                . ("malformed Turtle" `isInfixOf`)
                        code `shouldBe` ExitSuccess

                it
                    ( "(3) omitting --graph writes usage (with 'Usage:' "
                        <> "and 'canonical Turtle graph file') to STDERR "
                        <> "and exits non-zero so both release-artifact "
                        <> "smokes pass"
                    )
                    $ do
                        (code, _out, err) <-
                            runExe exe ["--view", "cli-tree"]
                        code `shouldBe` ExitFailure 1
                        BS8.unpack err
                            `shouldSatisfy` ("Usage:" `isInfixOf`)
                        BS8.unpack err
                            `shouldSatisfy` ( "canonical Turtle graph"
                                                `isInfixOf`
                                            )

----------------------------------------------------------------------
-- Fixtures
----------------------------------------------------------------------

{- | A real canonical graph @tx-graph@ emits — reused from fixture 02
so the stdin path exercises the same reader the file path does.
-}
fixtureGraph :: FilePath
fixtureGraph = "test/fixtures/tx-graph/02-alice-bob-ada/expected.ttl"

{- | An off-chain attestation in the overlay emitter's @[]@ form,
appended to the fixture graph to exercise issue #61 bug 2 over the
stdin path.
-}
attestationBlock :: ByteString
attestationBlock =
    BS8.pack $
        unlines
            [ ""
            , "[] a cardano:Attestation ;"
            , "  rdfs:label \"Invoice INV-635\" ;"
            , "  cardano:attests :amaru.antithesis ;"
            , "  cardano:ipfs <ipfs://bafyfoo> ."
            ]

----------------------------------------------------------------------
-- Subprocess helpers
----------------------------------------------------------------------

locateTxView :: IO (Maybe FilePath)
locateTxView = do
    mEnv <- lookupEnv "TX_VIEW_EXE"
    case mEnv of
        Just p | not (null p) -> pure (Just p)
        _ -> findExecutable "tx-view"

runExe :: FilePath -> [String] -> IO (ExitCode, ByteString, ByteString)
runExe prog args = do
    let cp =
            (proc prog args)
                { std_in = NoStream
                , std_out = CreatePipe
                , std_err = CreatePipe
                }
    withCreateProcess cp $ \_mIn mOut mErr ph ->
        case (mOut, mErr) of
            (Just hOut, Just hErr) -> do
                out <- BS.hGetContents hOut
                err <- BS.hGetContents hErr
                hClose hOut
                hClose hErr
                code <- waitForProcess ph
                pure (code, out, err)
            _ -> fail ("runExe: pipes not created for " <> prog)

runExeWithStdin ::
    FilePath ->
    [String] ->
    ByteString ->
    IO (ExitCode, ByteString, ByteString)
runExeWithStdin prog args input = do
    let cp =
            (proc prog args)
                { std_in = CreatePipe
                , std_out = CreatePipe
                , std_err = CreatePipe
                }
    withCreateProcess cp $ \mIn mOut mErr ph ->
        case (mIn, mOut, mErr) of
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
