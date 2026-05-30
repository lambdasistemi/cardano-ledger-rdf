{- |
Module      : Cardano.Tx.Graph.Rules.LoadExeSpec
Description : End-to-end tests for the @cq-rdf overlay@ executable surface.
License     : Apache-2.0

Drives the freshly-built @cq-rdf@ binary as a subprocess to exercise
the overlay CLI surface:

* @cq-rdf overlay --in \<fixture\>/rules.yaml@ on a basic fixture produces
  exit 0, an empty stderr, and a stdout byte-stream that equals the
  fixture's @expected.entities.ttl@.
* @cq-rdf overlay --in \<cycle\>@ on a rules graph with an import cycle
  produces a non-zero exit and a stderr line containing the
  @RulesImportCycle@ tag from
  'Cardano.Tx.Graph.Rules.Load.renderRulesLoadError'.
* @cq-rdf@ with no arguments produces exit 0 and a stderr help block
  that mentions the @overlay@ subcommand and the @Cardano RDF pipeline
  primitives@ header. Exit 0 is mandated by the release-artifact-smoke
  contract (the smoke runs the freshly-built binary with no args and
  greps its stderr).

The binary is located via the @CQ_RDF_EXE@ environment variable
when set (the @nix flake check@ sandbox and the @just unit@ recipe
both export it), or via @cabal list-bin -O0 exe:cq-rdf@ as a
fallback for bare @cabal test@ invocations in the dev shell. The
env-var path keeps the spec usable inside the @nix@ check sandbox,
which has no @cabal@ on @PATH@.
-}
module Cardano.Tx.Graph.Rules.LoadExeSpec (spec) where

import Control.Monad (unless)
import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BS8
import Data.List (isInfixOf)
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
    expectationFailure,
    it,
    runIO,
    shouldBe,
    shouldSatisfy,
 )

----------------------------------------------------------------------
-- Spec
----------------------------------------------------------------------

spec :: Spec
spec = describe "cq-rdf overlay executable" $ do
    cqRdfPath <- runIO locateCqRdf
    it
        ( "overlay --in <fixture-02>/rules.yaml — exit 0, stdout byte-equals"
            <> " expected.entities.ttl, stderr empty"
        )
        $ do
            let rulesPath =
                    "test/fixtures/tx-graph"
                        </> "02-alice-bob-ada"
                        </> "rules.yaml"
                expectedPath =
                    "test/fixtures/tx-graph"
                        </> "02-alice-bob-ada"
                        </> "expected.entities.ttl"
            expected <- BS.readFile expectedPath
            (code, out, err) <-
                runExe cqRdfPath ["overlay", "--in", rulesPath]
            err `shouldBe` BS.empty
            unless (out == expected) $
                expectationFailure $
                    unlines
                        [ "tx-graph stdout did not match "
                            <> expectedPath
                        , "--- expected (first 400 bytes):"
                        , take 400 (showBytes expected)
                        , "--- actual (first 400 bytes):"
                        , take 400 (showBytes out)
                        ]
            code `shouldBe` ExitSuccess

    it
        ( "overlay --in <cycle.yaml> — non-zero exit, stderr contains"
            <> " RulesImportCycle"
        )
        $ do
            withSystemTempDirectory "tx-graph-cycle" $ \dir -> do
                let aPath = dir </> "a.yaml"
                    bPath = dir </> "b.yaml"
                BS.writeFile aPath $
                    "imports:\n  - b.yaml\nentities:\n"
                        <> "  - name: a_ent\n"
                        <> "    script: "
                        <> hex28A
                        <> "\n"
                BS.writeFile bPath $
                    "imports:\n  - a.yaml\nentities:\n"
                        <> "  - name: b_ent\n"
                        <> "    script: "
                        <> hex28B
                        <> "\n"
                (code, _out, err) <-
                    runExe cqRdfPath ["overlay", "--in", aPath]
                code `shouldSatisfy` isFailure
                BS8.unpack err
                    `shouldSatisfy` ("RulesImportCycle" `isInfixOf`)

    it "no arguments — exit 0, stderr usage mentions overlay (release-artifact-smoke contract)" $ do
        (code, _out, err) <- runExe cqRdfPath []
        code `shouldBe` ExitSuccess
        BS8.unpack err
            `shouldSatisfy` ("overlay" `isInfixOf`)
        BS8.unpack err
            `shouldSatisfy` ("Cardano RDF pipeline primitives" `isInfixOf`)

----------------------------------------------------------------------
-- Subprocess helpers
----------------------------------------------------------------------

{- | Locate the freshly-built @cq-rdf@ binary.

If the @CQ_RDF_EXE@ environment variable is set, use it directly.
This is the path the @nix flake check@ sandbox takes — the @unit@
gate exports it pointing at the haskell.nix-built executable's store
path before invoking @unit-tests@. The @just unit@ recipe takes the
same path so the dev shell never needs @cabal@ as a runtime tool of
the test suite.

If unset, fall back to @cabal list-bin -O0 exe:cq-rdf@ so a bare
@cabal test cardano-rdf:unit-tests@ in the dev shell still
self-locates the binary. The nix-check sandbox has no @cabal@ on
@PATH@; using only the env-var path there keeps the suite working
without making @cabal@ a runtime dep of the check derivation.

Fails loudly with the captured @cabal@ stderr if neither route
resolves so a regression in the cabal stanza surfaces as an
actionable test failure rather than a confusing @no such file@ from
'runExe'.
-}
locateCqRdf :: IO FilePath
locateCqRdf = do
    mEnvPath <- lookupEnv "CQ_RDF_EXE"
    case mEnvPath of
        Just p | not (null p) -> pure p
        _ -> do
            (code, out, err) <-
                runExe
                    "cabal"
                    [ "list-bin"
                    , "-O0"
                    , "exe:cq-rdf"
                    ]
            case code of
                ExitSuccess ->
                    pure (trimTrailingNewline (BS8.unpack out))
                _ ->
                    fail $
                        "cabal list-bin exe:cq-rdf failed: " <> BS8.unpack err

-- | Spawn an external program, capture stdout + stderr, return exit code.
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
            _ ->
                fail $
                    "runExe: stdout/stderr pipes not created for " <> prog

-- | Non-zero exit detector.
isFailure :: ExitCode -> Bool
isFailure ExitSuccess = False
isFailure (ExitFailure _) = True

-- | Strip a single trailing newline from a 'String'.
trimTrailingNewline :: String -> String
trimTrailingNewline s = case reverse s of
    '\n' : rest -> reverse rest
    _ -> s

-- | Render a 'ByteString' as a Latin-1 'String' for diff dumps.
showBytes :: ByteString -> String
showBytes = map (toEnum . fromEnum) . BS.unpack

----------------------------------------------------------------------
-- Fixture bytes (cycle test)
----------------------------------------------------------------------

{- | Two distinct 28-byte hex blobs the cycle test uses for the
@script:@ fields of @a_ent@ / @b_ent@. Each starts with an
alphabetic nibble so YAML decodes the value as a string, not as
a number.
-}
hex28A, hex28B :: ByteString
hex28A = "aa11111111111111111111111111111111111111111111111111111a"
hex28B = "bb22222222222222222222222222222222222222222222222222222b"
