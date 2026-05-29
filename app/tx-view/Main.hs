{- |
Module      : Main
Description : tx-view executable — packaged-view dispatcher over canonical Turtle graphs.
License     : Apache-2.0

Companion executable to @tx-graph@. Loads a canonical Turtle graph
file and projects it through a named packaged view, writing the
rendered byte stream to stdout or to a file.

CLI surface (#51, locked by spec FR-002; stdin added in #61):

* @--graph FILE@ — canonical Turtle graph (the kind @tx-graph@ emits).
* @--graph -@ — read the canonical Turtle graph from stdin, so the
  pipeline @tx-graph ... | tx-view --view cli-tree@ works without a
  temporary file. Mirrors how @tx-graph@ treats @-@ on its input.
* @--view NAME@ — one of @cli-tree@; defaults to @cli-tree@.
* @--out FILE@ — output destination; defaults to stdout.

Exit codes:

* 0 — view rendered successfully (empty result counts as success per FR-008).
* 1 — structured 'Cardano.Tx.View.ViewError': unknown view name or
  malformed Turtle.
* \>=2 — @optparse-applicative@ usage error (missing @--graph@ with no input, etc.)
  or an OS-level failure reading the graph or writing the output.
-}
module Main (main) where

import Control.Exception (IOException, try)
import Data.ByteString qualified as BS
import Data.Text qualified as Text
import Options.Applicative (
    Parser,
    ParserInfo,
    execParser,
    fullDesc,
    header,
    help,
    helper,
    info,
    long,
    metavar,
    optional,
    progDesc,
    showDefault,
    strOption,
    value,
    (<**>),
 )
import System.Exit (ExitCode (..), exitSuccess, exitWith)
import System.IO (hPutStrLn, stderr, stdin, stdout)

import Cardano.Tx.View (
    ViewError (..),
    parseViewName,
    renderView,
    renderViewError,
 )

----------------------------------------------------------------------
-- Options
----------------------------------------------------------------------

data Options = Options
    { optGraph :: !(Maybe FilePath)
    , optView :: !String
    , optOut :: !(Maybe FilePath)
    }

optionsParser :: Parser Options
optionsParser =
    Options
        <$> optional
            ( strOption
                ( long "graph"
                    <> metavar "FILE"
                    <> help
                        ( "Canonical Turtle graph file (from "
                            <> "tx-graph). '-' reads the graph from "
                            <> "stdin, so 'tx-graph ... | tx-view' "
                            <> "works without a temporary file."
                        )
                )
            )
        <*> strOption
            ( long "view"
                <> metavar "NAME"
                <> value "cli-tree"
                <> showDefault
                <> help "Packaged view name (currently: cli-tree)."
            )
        <*> optional
            ( strOption
                ( long "out"
                    <> metavar "FILE"
                    <> help "Output destination (default: stdout)."
                )
            )

optionsInfo :: ParserInfo Options
optionsInfo =
    info
        (optionsParser <**> helper)
        ( fullDesc
            <> header
                ( "tx-view — packaged-view dispatcher over canonical "
                    <> "Turtle graphs"
                )
            <> progDesc
                ( "Loads a canonical Turtle graph file (the kind "
                    <> "tx-graph emits) and projects it through a "
                    <> "named packaged view, writing the rendered "
                    <> "byte stream to stdout or to --out FILE."
                )
        )

----------------------------------------------------------------------
-- Entry point
----------------------------------------------------------------------

main :: IO ()
main = do
    opts <- execParser optionsInfo
    view <- case parseViewName (optView opts) of
        Right v -> pure v
        Left err -> exitOnViewError err
    bs <- readGraphSource (optGraph opts)
    case renderView view bs of
        Left err -> exitOnViewError err
        Right out -> writeOutput (optOut opts) out

----------------------------------------------------------------------
-- IO helpers
----------------------------------------------------------------------

{- | Resolve the @--graph@ source. @-@ reads the canonical Turtle
graph from stdin (enabling the @tx-graph ... | tx-view@ pipeline);
any other value is a file path; omitting @--graph@ is a usage error
with a helpful message.
-}
readGraphSource :: Maybe FilePath -> IO BS.ByteString
readGraphSource = \case
    Nothing -> do
        -- No --graph: emit usage on stderr and exit 2. Both release
        -- smokes inspect stderr for "Usage:" and the documented
        -- "canonical Turtle graph file" substring; the Darwin smoke
        -- additionally requires a non-zero exit when invoked with no
        -- arguments (it treats success as a smoke failure). Operators
        -- wanting stdin pass `--graph -` explicitly.
        hPutStrLn stderr $
            unlines
                [ "Usage: tx-view --graph FILE [--view NAME] [--out FILE]"
                , "       tx-view --graph - [--view NAME] [--out FILE]"
                , ""
                , "Loads a canonical Turtle graph file (the kind"
                , "tx-graph emits) and projects it through a named"
                , "packaged view, writing the rendered byte stream"
                , "to stdout or to --out FILE. Use --graph - to read"
                , "the graph from stdin (e.g. `tx-graph ... | tx-view`)."
                ]
        exitWith (ExitFailure 1)
    Just "-" -> BS.hGetContents stdin
    Just path -> readGraphOrExit path

readGraphOrExit :: FilePath -> IO BS.ByteString
readGraphOrExit path = do
    res <- try (BS.readFile path) :: IO (Either IOException BS.ByteString)
    case res of
        Right bs -> pure bs
        Left ioErr -> do
            hPutStrLn stderr $
                "tx-view: failed to read --graph file "
                    <> show path
                    <> ": "
                    <> show ioErr
            exitWith (ExitFailure 1)

writeOutput :: Maybe FilePath -> BS.ByteString -> IO ()
writeOutput mPath bs = case mPath of
    Nothing -> do
        BS.hPut stdout bs
        exitSuccess
    Just p -> do
        res <- try (BS.writeFile p bs) :: IO (Either IOException ())
        case res of
            Right () -> exitSuccess
            Left ioErr -> do
                hPutStrLn stderr $
                    "tx-view: failed to write --out file "
                        <> show p
                        <> ": "
                        <> show ioErr
                exitWith (ExitFailure 1)

exitOnViewError :: ViewError -> IO a
exitOnViewError err = do
    hPutStrLn stderr (Text.unpack (renderViewError err))
    exitWith (ExitFailure 1)
