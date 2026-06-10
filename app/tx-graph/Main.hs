{-# LANGUAGE TypeApplications #-}

{- |
Module      : Main
Description : cq-rdf executable — Cardano RDF subcommands.
License     : Apache-2.0

Renders operator-authored overlays, transaction bodies, blueprint
typed-decode decorations, and SHACL reports as separate Unix-pipe
subcommands.

CLI surface (see issue #114 — operator-led role audit consolidation):

* @--rules FILE@ — operator overlay + blueprints + attestations.
  Used alone, emits overlay-only Turtle to stdout. Combined with
  inputs, merged into the joint graph(s).
* @--provider koios|blockfrost|http@ — fetch the input CBOR from an
  HTTP indexer instead of reading a file. With a fetching provider the
  positional argument / @--in@ is a 64-hex txid. Default @file@ keeps
  the positional as a CBOR path.
* @--token TOKEN@ — bearer / API token (blockfrost @project_id@;
  optional koios / http bearer).
* @--url URL@ — provider base URL (required for @http@; overrides the
  default for koios / blockfrost).
* Positional @CBOR@ — one Conway transaction CBOR file (file mode) or a
  txid (provider mode).
* @-@ in the positional slot — read a single Conway tx from stdin
  (file mode only).
* @--out FILE@ — write one graph to @FILE@ instead of stdout.
* @--format turtle|json-ld@ — output format (default @turtle@).

Inside, the input CBOR is parsed and indexed by its computed
@TxId@ (@hashAnnotated . bodyTxL@). The resolver looks each
spending / reference / collateral input up in that one-transaction
map; when an input's parent CBOR is not the same transaction the
resolver returns @Nothing@ and the emitter falls back to raw-bytes.

Exit codes:

* 0 — overlay or graph(s) emitted successfully.
* 1 — structured 'Cardano.Tx.Graph.Rules.Load.RulesLoadError' or
  'Cardano.Tx.Graph.Emit.EmitError'.
* >=2 — @optparse-applicative@ usage error or invalid flag
  combination (e.g. multiple positional inputs).
-}
module Main (main) where

import Cardano.Tx.Blueprint (
    Blueprint (..),
    BlueprintArgument (..),
    BlueprintPreamble (..),
    BlueprintSchema (..),
    BlueprintValidator (..),
    OpenValue (..),
    parseBlueprintJSON,
    resolveBlueprintSchema,
 )
import Cardano.Tx.Graph.Emit
import Cardano.Tx.Graph.Emit.Blueprint (decodeDatumForScriptHash)
import Cardano.Tx.Graph.Rules.Load (
    EntityDecl,
    RulesLoadResult (..),
    loadRulesFile,
    renderRulesLoadError,
    renderRulesLoadWarning,
    rulesEntities,
 )
import Cardano.Tx.Metadata.Project (
    TurtleGraph (..),
    enrichMetadataTurtle,
    ensureTrailingNewline,
    literalFor,
    objectFor,
    parseCanonicalTurtle,
    turtleString,
 )
import Cardano.Tx.Metadata.Schema (
    loadMetadataSchemaDirectory,
    renderMetadataSchemaParseError,
 )

import Cardano.Ledger.Hashes (ScriptHash (..), extractHash, hashAnnotated)
import Data.Text (Text)

import Cardano.Crypto.Hash (hashFromBytes, hashToBytes)
import Cardano.Ledger.Api.Scripts.Data (Data)
import Cardano.Ledger.Binary (decCBOR, decodeFullDecoder, natVersion)
import Control.Monad (forM, unless, when)
import Data.Aeson qualified as Aeson
import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KeyMap
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BS8
import Data.ByteString.Lazy qualified as LBS
import Data.Foldable (toList)
import Data.List qualified as List
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust, mapMaybe)
import Data.Set (Set)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as TextEncoding
import Data.Text.Encoding.Error (lenientDecode)
import Options.Applicative (
    Parser,
    ParserInfo,
    ParserPrefs,
    ParserResult (Failure),
    argument,
    command,
    customExecParser,
    defaultPrefs,
    eitherReader,
    fullDesc,
    handleParseResult,
    header,
    help,
    helper,
    info,
    long,
    many,
    metavar,
    option,
    optional,
    parserFailure,
    prefs,
    progDesc,
    renderFailure,
    showDefault,
    showHelpOnEmpty,
    showHelpOnError,
    strOption,
    subparser,
    value,
    (<**>),
 )
import Options.Applicative.Types (ParseError (ErrorMsg, ShowHelpText))
import System.Directory (
    doesDirectoryExist,
    getTemporaryDirectory,
    listDirectory,
    removeFile,
 )
import System.Environment (getArgs, getProgName)
import System.Exit (ExitCode (..), exitSuccess, exitWith)
import System.FilePath (takeFileName, (</>))
import System.IO (hClose, hPutStrLn, openTempFile, stderr, stdin, stdout)
import System.IO.Error (catchIOError)
import System.Process (readProcessWithExitCode)

import Cardano.Ledger.Api.Tx (bodyTxL)
import Cardano.Ledger.Api.Tx.Body (
    collateralInputsTxBodyL,
    inputsTxBodyL,
    outputsTxBodyL,
    referenceInputsTxBodyL,
 )
import Cardano.Ledger.Api.Tx.Out (TxOut)
import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.TxIn (TxId (..), TxIn (..))
import Data.ByteString.Base16 qualified as Base16
import Data.Set qualified as Set
import Lens.Micro ((^.))

import Data.Char (isHexDigit)
import Network.HTTP.Client.TLS (newTlsManager)

import Cardano.Tx.Decode (decodeConwayTxInput)
import Cardano.Tx.Graph.Provider (
    CborProvider,
    ProviderConfig (..),
    fetchCbor,
    parseProviderArg,
    renderProviderError,
 )
import Cardano.Tx.Graph.Resolve (Resolver (..), resolveChain)
import Cardano.Tx.Ledger (ConwayTx)

{- | Command-line options. Issue #59 consolidation: @--rules@,
optional single positional CBOR / stdin, @--out@, and @--format@.
-}
data Options = Options
    { optRulesFile :: !(Maybe FilePath)
    , optProvider :: !(Maybe CborProvider)
    , optToken :: !(Maybe Text)
    , optUrl :: !(Maybe Text)
    , optPositional :: ![InputSource]
    , optIn :: !(Maybe FilePath)
    , optOut :: !(Maybe FilePath)
    , optFormat :: !String
    }

{- | Where to read one Conway tx CBOR from. @-@ on the positional
slot maps to 'TxFromStdin'; every other positional argument is a
file path.
-}
data InputSource
    = TxFromFile FilePath
    | TxFromStdin
    deriving stock (Eq, Show)

data Command
    = CmdOverlay !OverlayOptions
    | CmdBody !BodyOptions
    | CmdBlueprint !BlueprintOptions
    | CmdMetadata !MetadataOptions
    | CmdShacl !ShaclOptions

data OverlayOptions = OverlayOptions
    { overlayIn :: !(Maybe FilePath)
    , overlayOut :: !(Maybe FilePath)
    }

data BodyOptions = BodyOptions
    { bodyProvider :: !(Maybe CborProvider)
    , bodyToken :: !(Maybe Text)
    , bodyUrl :: !(Maybe Text)
    , bodyPositional :: ![InputSource]
    , bodyIn :: !(Maybe FilePath)
    , bodyOut :: !(Maybe FilePath)
    , bodyFormat :: !String
    }

newtype BlueprintOptions = BlueprintOptions
    { blueprintDir :: FilePath
    }

newtype MetadataOptions = MetadataOptions
    { metadataSchemas :: FilePath
    }

data ShaclSeverity
    = ShaclViolationOnly
    | ShaclWarningAndViolation
    deriving stock (Eq, Show)

data ShaclOptions = ShaclOptions
    { shaclShapes :: !FilePath
    , shaclOut :: !(Maybe FilePath)
    , shaclSeverity :: !ShaclSeverity
    }

data BlueprintRegistry = BlueprintRegistry
    { registryIndexed :: ![(ScriptHash, Blueprint, Text)]
    , registryFallback :: ![(Blueprint, Text)]
    }

commandParser :: Parser Command
commandParser =
    subparser
        ( command
            "overlay"
            ( info
                (CmdOverlay <$> overlayOptionsParser <**> helper)
                ( progDesc
                    "Read an overlay YAML/Turtle file and emit overlay-only Turtle."
                )
            )
            <> command
                "body"
                ( info
                    (CmdBody <$> bodyOptionsParser <**> helper)
                    ( progDesc
                        ( "Read one transaction CBOR path/stdin or fetch one "
                            <> "txid via --provider, then emit body-only RDF. "
                            <> "Deprecated tx-graph --rules users should run "
                            <> "'cq-rdf overlay --in rules.yaml' separately "
                            <> "and concatenate it with this output."
                        )
                    )
                )
            <> command
                "blueprint"
                ( info
                    (CmdBlueprint <$> blueprintOptionsParser <**> helper)
                    ( progDesc
                        "Read Turtle on stdin and append CIP-57 typed datum triples."
                    )
                )
            <> command
                "metadata"
                ( info
                    (CmdMetadata <$> metadataOptionsParser <**> helper)
                    ( progDesc
                        "Read Turtle on stdin and append schema-typed metadata triples."
                    )
                )
            <> command
                "shacl"
                ( info
                    (CmdShacl <$> shaclOptionsParser <**> helper)
                    ( progDesc
                        "Read Turtle on stdin and emit a SHACL validation report."
                    )
                )
        )

commandInfo :: ParserInfo Command
commandInfo =
    info
        (commandParser <**> helper)
        ( fullDesc
            <> header "cq-rdf — Cardano RDF pipeline primitives"
            <> progDesc
                ( "Pure subcommands: overlay (YAML/Turtle to overlay TTL), "
                    <> "body (txid/CBOR to body TTL), blueprint (TTL to typed "
                    <> "datum TTL), metadata (TTL to typed metadata TTL), "
                    <> "and shacl (TTL to validation report)."
                )
        )

overlayOptionsParser :: Parser OverlayOptions
overlayOptionsParser =
    OverlayOptions
        <$> optional
            ( strOption
                ( long "in"
                    <> metavar "FILE"
                    <> help "Read overlay YAML/Turtle from FILE; '-' or omitted reads stdin."
                )
            )
        <*> optional
            ( strOption
                ( long "out"
                    <> metavar "FILE"
                    <> help "Write overlay Turtle to FILE instead of stdout."
                )
            )

bodyOptionsParser :: Parser BodyOptions
bodyOptionsParser =
    BodyOptions
        <$> option
            (eitherReader parseProviderArg)
            ( long "provider"
                <> metavar "PROVIDER"
                <> value Nothing
                <> help
                    ( "CBOR source: file | koios | blockfrost | http "
                        <> "(default: file). With a fetching provider the "
                        <> "positional argument / --in is a 64-hex txid."
                    )
            )
        <*> optional
            ( Text.pack
                <$> strOption
                    ( long "token"
                        <> metavar "TOKEN"
                        <> help "Bearer / API token for the provider."
                    )
            )
        <*> optional
            ( Text.pack
                <$> strOption
                    ( long "url"
                        <> metavar "URL"
                        <> help "Provider base URL."
                    )
            )
        <*> many
            ( argument
                readInputSource
                ( metavar "CBOR|TXID"
                    <> help
                        ( "Conway tx CBOR file path, '-' for stdin, "
                            <> "or txid with --provider."
                        )
                )
            )
        <*> optional
            ( strOption
                ( long "in"
                    <> metavar "FILE"
                    <> help "Read one Conway tx CBOR from FILE."
                )
            )
        <*> optional
            ( strOption
                ( long "out"
                    <> metavar "FILE"
                    <> help "Write one body graph to FILE instead of stdout."
                )
            )
        <*> strOption
            ( long "format"
                <> metavar "FORMAT"
                <> value "turtle"
                <> showDefault
                <> help "Output format: 'turtle' or 'json-ld'."
            )
  where
    readInputSource =
        eitherReader $ \case
            "-" -> Right TxFromStdin
            path -> Right (TxFromFile path)

blueprintOptionsParser :: Parser BlueprintOptions
blueprintOptionsParser =
    BlueprintOptions
        <$> strOption
            ( long "blueprints"
                <> metavar "DIR"
                <> help "Directory containing *.cip57.json blueprint files."
            )

metadataOptionsParser :: Parser MetadataOptions
metadataOptionsParser =
    MetadataOptions
        <$> strOption
            ( long "schemas"
                <> metavar "DIR"
                <> help "Directory containing *.schema.json metadata schema files."
            )

shaclOptionsParser :: Parser ShaclOptions
shaclOptionsParser =
    ShaclOptions
        <$> strOption
            ( long "shapes"
                <> metavar "DIR"
                <> help "Directory containing *.shacl.ttl shape files."
            )
        <*> optional
            ( strOption
                ( long "out"
                    <> metavar "FILE"
                    <> help "Write the SHACL report to FILE instead of stdout."
                )
            )
        <*> option
            (eitherReader parseSeverity)
            ( long "severity"
                <> metavar "SEVERITY"
                <> value ShaclViolationOnly
                <> showDefault
                <> help "Failure threshold: violation or warning."
            )

parseSeverity :: String -> Either String ShaclSeverity
parseSeverity = \case
    "violation" -> Right ShaclViolationOnly
    "warning" -> Right ShaclWarningAndViolation
    other -> Left ("unknown severity: " <> other)

optionsParser :: Parser Options
optionsParser =
    Options
        <$> optional
            ( strOption
                ( long "rules"
                    <> metavar "FILE"
                    <> help
                        ( "Operator-authored rules file (.yaml/"
                            <> ".yml or .ttl). Used alone, emits "
                            <> "overlay-only Turtle to stdout. "
                            <> "Combined with input, merged into "
                            <> "the graph."
                        )
                )
            )
        <*> option
            (eitherReader parseProviderArg)
            ( long "provider"
                <> metavar "PROVIDER"
                <> value Nothing
                <> help
                    ( "CBOR source: file | koios | blockfrost | "
                        <> "http (default: file). With a fetching "
                        <> "provider the positional argument / --in "
                        <> "is a 64-hex txid, not a CBOR path."
                    )
            )
        <*> optional
            ( Text.pack
                <$> strOption
                    ( long "token"
                        <> metavar "TOKEN"
                        <> help
                            ( "Bearer / API token for the provider "
                                <> "(blockfrost project_id; optional "
                                <> "koios / http bearer)."
                            )
                    )
            )
        <*> optional
            ( Text.pack
                <$> strOption
                    ( long "url"
                        <> metavar "URL"
                        <> help
                            ( "Provider base URL. Required for the "
                                <> "'http' provider; overrides the "
                                <> "default for koios / blockfrost."
                            )
                    )
            )
        <*> many
            ( argument
                readInputSource
                ( metavar "CBOR"
                    <> help
                        ( "Conway tx CBOR file paths. '-' reads "
                            <> "one tx from stdin."
                        )
                )
            )
        <*> optional
            ( strOption
                ( long "in"
                    <> metavar "FILE"
                    <> help
                        ( "Read one Conway tx CBOR from FILE "
                            <> "instead of the positional argument "
                            <> "or stdin. Mutually exclusive with "
                            <> "the positional CBOR."
                        )
                )
            )
        <*> optional
            ( strOption
                ( long "out"
                    <> metavar "FILE"
                    <> help "Write one graph to FILE instead of stdout."
                )
            )
        <*> strOption
            ( long "format"
                <> metavar "FORMAT"
                <> value "turtle"
                <> showDefault
                <> help "Output format: 'turtle' or 'json-ld'."
            )
  where
    readInputSource =
        eitherReader $ \case
            "-" -> Right TxFromStdin
            path -> Right (TxFromFile path)

optionsInfo :: ParserInfo Options
optionsInfo =
    info
        (optionsParser <**> helper)
        ( fullDesc
            <> header "tx-graph — pure (rules + cbor) → ttl transformation"
            <> progDesc
                ( "tx-graph — operator-entity overlay + body "
                    <> "emitter. Loads operator-authored rules "
                    <> "(overlay-only mode) or emits one graph "
                    <> "from one Conway transaction CBOR "
                    <> "(positional path / stdin, or a txid fetched "
                    <> "via --provider koios|blockfrost|http). "
                    <> "Output format defaults to Turtle; operators "
                    <> "compose multiple tx graphs by concatenating "
                    <> "stdout."
                )
        )

main :: IO ()
main = do
    prog <- takeFileName <$> getProgName
    args <- getArgs
    case args of
        [] ->
            if prog == "tx-graph"
                then printHelpAndExitSuccess prog optionsInfo
                else printHelpAndExitSuccess prog commandInfo
        _ ->
            if prog == "tx-graph"
                then customExecParser helpfulPrefs optionsInfo >>= dispatchLegacy
                else customExecParser helpfulPrefs commandInfo >>= dispatchCommand

{- | Parser preferences that show the help block when the binary is invoked
with no arguments and on usage errors. This keeps the release-pipeline smoke
test (@<binary>@ with no args grep-checked for a usage substring) green for
subcommand-style CLIs.
-}
helpfulPrefs :: ParserPrefs
helpfulPrefs = prefs (showHelpOnEmpty <> showHelpOnError)

{- | Render the parser's help block to stderr and exit 0. Used when the
binary is invoked with no arguments — both for @cq-rdf@ (subcommand-style,
where the default 'showHelpOnEmpty' still exits non-zero on 'MissingError')
and for the legacy @tx-graph@ entry point (no required arguments).
Writing the help to stderr matches the @linux-artifact-smoke@ contract
(stderr-only diagnostic capture).
-}
printHelpAndExitSuccess :: String -> ParserInfo a -> IO ()
printHelpAndExitSuccess prog pinfo = do
    let failure = parserFailure helpfulPrefs pinfo (ShowHelpText Nothing) []
        (msg, _) = renderFailure failure prog
    hPutStrLn stderr msg
    exitSuccess

dispatchCommand :: Command -> IO ()
dispatchCommand = \case
    CmdOverlay opts -> overlayCommand opts
    CmdBody opts -> bodyCommand opts
    CmdBlueprint opts -> blueprintCommand opts
    CmdMetadata opts -> metadataCommand opts
    CmdShacl opts -> shaclCommand opts

{- | Dispatch on input presence. Overlay-only when @--rules@ is the
sole input flag; joint emit when at least one CBOR source is
present.
-}
dispatchLegacy :: Options -> IO ()
dispatchLegacy opts = do
    when (isJust (optRulesFile opts)) $
        hPutStrLn
            stderr
            ( "deprecation: --rules is deprecated; use "
                <> "'cq-rdf overlay --in X' and pipe + "
                <> "'cq-rdf body' for the body emit. See #66."
            )
    input <- collectInput opts
    case (optRulesFile opts, input) of
        (Just rulesPath, Nothing) ->
            overlayOnly rulesPath
        (_, Nothing) ->
            usageError
                ( "missing input: pass --rules (overlay-only), "
                    <> "or one positional CBOR file (see --help)."
                )
        (_, Just source) ->
            emitOne opts source

overlayCommand :: OverlayOptions -> IO ()
overlayCommand OverlayOptions{overlayIn, overlayOut} =
    withOverlayInput overlayIn $ \path -> do
        bytes <- overlayBytes path
        writeOutput overlayOut bytes

bodyCommand :: BodyOptions -> IO ()
bodyCommand opts = do
    input <- collectBodyInput opts
    case input of
        Nothing ->
            usageErrorWith
                commandInfo
                "missing input: pass one positional CBOR file, '-' for stdin, or a txid with --provider."
        Just source ->
            emitOne (bodyAsOptions opts) source

bodyAsOptions :: BodyOptions -> Options
bodyAsOptions BodyOptions{bodyProvider, bodyToken, bodyUrl, bodyPositional, bodyIn, bodyOut, bodyFormat} =
    Options
        { optRulesFile = Nothing
        , optProvider = bodyProvider
        , optToken = bodyToken
        , optUrl = bodyUrl
        , optPositional = bodyPositional
        , optIn = bodyIn
        , optOut = bodyOut
        , optFormat = bodyFormat
        }

{- | Resolve positional input to zero or one 'InputSource'. Multiple
positional CBOR files are intentionally rejected; operators compose
multiple transactions with a shell loop and stdout concatenation.
-}
collectInput :: Options -> IO (Maybe InputSource)
collectInput opts =
    case (optPositional opts, optIn opts) of
        ([], Nothing) -> pure Nothing
        ([], Just path) -> pure (Just (TxFromFile path))
        ([source], Nothing) -> pure (Just source)
        ([_], Just _) -> do
            usageError
                ( "--in is mutually exclusive with the "
                    <> "positional CBOR argument."
                )
            pure Nothing
        (sources, _) -> do
            usageError
                ( "expected at most one CBOR input, got "
                    <> show (length sources)
                    <> ". Compose multiple transactions with a "
                    <> "shell loop and stdout concatenation."
                )
            pure Nothing

collectBodyInput :: BodyOptions -> IO (Maybe InputSource)
collectBodyInput opts =
    collectInput (bodyAsOptions opts)

{- | Pretty usage error: print one line on stderr and let
@optparse-applicative@ render help with exit code 2.
-}
usageError :: String -> IO ()
usageError =
    usageErrorWith optionsInfo

usageErrorWith :: ParserInfo a -> String -> IO ()
usageErrorWith pinfo msg =
    handleParseResult
        ( Failure
            ( parserFailure
                defaultPrefs
                pinfo
                (ErrorMsg msg)
                []
            )
        )

writeOutput :: Maybe FilePath -> BS.ByteString -> IO ()
writeOutput = \case
    Just outPath -> BS.writeFile outPath
    Nothing -> BS.hPut stdout

overlayBytes :: FilePath -> IO BS.ByteString
overlayBytes rulesPath = do
    result <- loadRulesFile rulesPath
    case result of
        Right RulesLoadResult{rulesOverlayTurtle, rulesWarnings} -> do
            mapM_ (hPutStrLn stderr . renderRulesLoadWarning) rulesWarnings
            pure rulesOverlayTurtle
        Left err -> do
            hPutStrLn stderr (renderRulesLoadError err)
            exitWith (ExitFailure 1)

withOverlayInput :: Maybe FilePath -> (FilePath -> IO a) -> IO a
withOverlayInput (Just path) action
    | path /= "-" = action path
withOverlayInput _ action =
    withTempFile "cq-rdf-overlay" ".yaml" $ \path -> do
        BS.hGetContents stdin >>= BS.writeFile path
        action path

withTempFile :: String -> String -> (FilePath -> IO a) -> IO a
withTempFile prefix suffix action = do
    dir <- getTemporaryDirectory
    (path0, handle) <- openTempFile dir prefix
    hClose handle
    removeFile path0 `catchIOError` \_ -> pure ()
    let path = path0 <> suffix
    result <-
        action path `catchIOError` \err -> do
            removeFile path `catchIOError` \_ -> pure ()
            ioError err
    removeFile path `catchIOError` \_ -> pure ()
    pure result

{- | Overlay-only mode. Loads the rules file and writes the
canonical Turtle entity overlay to stdout.
-}
overlayOnly :: FilePath -> IO ()
overlayOnly rulesPath = do
    bytes <- overlayBytes rulesPath
    BS.hPut stdout bytes
    exitSuccess

{- | Body-emitting mode for one transaction. Parses the input,
indexes it by computed 'TxId', and emits one Turtle (or JSON-LD)
graph to stdout or @--out@.
-}
emitOne :: Options -> InputSource -> IO ()
emitOne opts source = do
    fmtChecked <- exitOnEmitError (parseFormat (optFormat opts))
    (entities, blueprints, overlay) <- case optRulesFile opts of
        Nothing -> pure ([], [], BS.empty)
        Just p -> loadOverlayAndEntitiesOrExit p
    entry@(_, tx) <- loadTx opts source
    let lattice = Map.singleton (txIdOf tx) tx
    bytes <- renderOne fmtChecked entities blueprints overlay lattice entry
    case optOut opts of
        Just outPath ->
            BS.writeFile outPath bytes
        Nothing ->
            BS.hPut stdout bytes

{- | Decode one transaction, dispatching on @--provider@. In file mode
(no provider, or @--provider file@) the input source is a local CBOR
path / stdin, handled by 'loadOne'. With a fetching provider the source
is a 64-hex txid that is fetched over HTTP and then decoded.
-}
loadTx :: Options -> InputSource -> IO (String, ConwayTx)
loadTx opts source =
    case optProvider opts of
        Nothing -> loadOne source
        Just provider -> do
            txid <- txidFromSource source
            manager <- newTlsManager
            let cfg =
                    ProviderConfig
                        { providerKind = provider
                        , providerUrl = optUrl opts
                        , providerToken = optToken opts
                        }
            fetched <- fetchCbor manager cfg txid
            case fetched of
                Left err ->
                    exitOnEmitError
                        ( Left
                            ( MalformedTxCbor
                                (Text.unpack txid)
                                (renderProviderError err)
                            )
                        )
                Right bytes ->
                    case decodeConwayTxInput bytes of
                        Right tx -> pure (Text.unpack txid, tx)
                        Left decErr ->
                            exitOnEmitError
                                ( Left
                                    ( MalformedTxCbor
                                        (Text.unpack txid)
                                        (Text.pack (show decErr))
                                    )
                                )

{- | Interpret an 'InputSource' as a lowercase-hex txid for provider
mode. Rejects stdin and any value that is not exactly 64 hex chars.
-}
txidFromSource :: InputSource -> IO Text
txidFromSource = \case
    TxFromStdin -> do
        usageError
            ( "stdin input is not supported with --provider; "
                <> "pass a 64-hex txid."
            )
        pure Text.empty
    TxFromFile raw ->
        let lower = Text.toLower (Text.pack raw)
         in if Text.length lower == 64 && Text.all isHexDigit lower
                then pure lower
                else do
                    usageError
                        ( "expected a 64-hex txid with --provider, "
                            <> "got: "
                            <> raw
                        )
                    pure Text.empty

{- | Decode one input source into @(label, ConwayTx)@. The label
is the file path (or @\<stdin\>@) and is used in error messages
only — the tx itself is keyed by its computed 'TxId' downstream.
-}
loadOne :: InputSource -> IO (String, ConwayTx)
loadOne src = do
    let label = case src of
            TxFromStdin -> "<stdin>"
            TxFromFile p -> p
    bsOrErr <- case src of
        TxFromStdin ->
            (Right <$> BS.hGetContents stdin)
                `catchIOError` (pure . Left . show)
        TxFromFile p ->
            (Right <$> BS.readFile p)
                `catchIOError` (pure . Left . show)
    case bsOrErr of
        Left ioMsg ->
            exitOnEmitError
                (Left (MalformedTxCbor label (Text.pack ioMsg)))
        Right bs ->
            case decodeConwayTxInput bs of
                Right tx ->
                    pure (label, tx)
                Left decErr ->
                    exitOnEmitError
                        ( Left
                            ( MalformedTxCbor
                                label
                                (Text.pack (show decErr))
                            )
                        )

{- | Compute the 'TxId' for a Conway transaction by hashing its
annotated body, matching the @hashAnnotated body@ pattern used in
the body emitter (#100).
-}
txIdOf :: ConwayTx -> TxId
txIdOf tx = TxId (hashAnnotated (tx ^. bodyTxL))

{- | Lowercase hex of a 'TxId', suitable for use as the stem of an
emitted @\<txid-hex\>.ttl@ file.
-}
txIdHex :: TxId -> String
txIdHex (TxId safeHash) =
    Text.unpack
        ( TextEncoding.decodeUtf8
            (Base16.encode (hashToBytes (extractHash safeHash)))
        )

{- | Resolve one tx against the in-memory lattice, emit it, and
serialise the result. Pure-ish wrapper around 'emit' + 'serialize'
that also forwards blueprint-decode warnings to stderr.
-}
renderOne ::
    EmitFormat ->
    [EntityDecl] ->
    [(ScriptHash, Blueprint, Text)] ->
    BS.ByteString ->
    Map TxId ConwayTx ->
    (String, ConwayTx) ->
    IO BS.ByteString
renderOne fmt entities blueprints overlay lattice (label, tx) = do
    utxo <- resolveAgainstLattice lattice tx
    warnOnMissingParents label tx lattice
    g <- exitOnEmitError (emit tx utxo entities blueprints)
    mapM_ (hPutStrLn stderr) (decodeErrorWarnings g)
    let txid = Text.pack (txIdHex (txIdOf tx))
        joint = g{graphOverlayTurtle = overlay}
    pure (serializeScoped fmt defaultSlug txid joint)

{- | Warn on stderr for every spending / reference / collateral
input whose parent tx isn't in the lattice. Per the role-audit
contract (#114): a missing parent is the operator's bug, surfaced
loudly; the emitter still produces raw-bytes fallback so the
graph remains well-formed.
-}
warnOnMissingParents :: String -> ConwayTx -> Map TxId ConwayTx -> IO ()
warnOnMissingParents label tx lattice = do
    let inputs = collectInputs tx
        missing =
            [ ip
            | ip@(TxIn parentTxId _) <- Set.toList inputs
            , not (Map.member parentTxId lattice)
            ]
    mapM_
        ( \(TxIn t (TxIx ix)) ->
            hPutStrLn
                stderr
                ( "warning: tx-graph: "
                    <> label
                    <> ": parent tx not in lattice for input "
                    <> txIdHex t
                    <> "#"
                    <> show ix
                )
        )
        missing

defaultSlug :: FilePath
defaultSlug = "tx"

----------------------------------------------------------------------
-- cq-rdf blueprint
----------------------------------------------------------------------

blueprintCommand :: BlueprintOptions -> IO ()
blueprintCommand BlueprintOptions{blueprintDir} = do
    ttl <- BS.hGetContents stdin
    index <- loadBlueprintDirectory blueprintDir
    enriched <- enrichBlueprintTurtle index ttl
    BS.hPut stdout enriched

metadataCommand :: MetadataOptions -> IO ()
metadataCommand MetadataOptions{metadataSchemas} = do
    ttl <- BS.hGetContents stdin
    loadedSchemas <- loadMetadataSchemaDirectory metadataSchemas
    schemas <- case loadedSchemas of
        Right loaded -> pure loaded
        Left err -> do
            hPutStrLn stderr (renderMetadataSchemaParseError err)
            exitWith (ExitFailure 1)
    enriched <- enrichMetadataTurtle schemas ttl
    BS.hPut stdout enriched

loadBlueprintDirectory :: FilePath -> IO BlueprintRegistry
loadBlueprintDirectory dir = do
    exists <- doesDirectoryExist dir
    unless exists $ do
        hPutStrLn stderr ("blueprint directory does not exist: " <> dir)
        exitWith (ExitFailure 1)
    names <- listDirectory dir
    loaded <-
        forM
            [dir </> name | name <- List.sort names, ".cip57.json" `List.isSuffixOf` name]
            loadBlueprintFile
    pure
        BlueprintRegistry
            { registryIndexed = concatMap fst loaded
            , registryFallback = concatMap snd loaded
            }

loadBlueprintFile ::
    FilePath ->
    IO ([(ScriptHash, Blueprint, Text)], [(Blueprint, Text)])
loadBlueprintFile path = do
    bytes <- LBS.readFile path
    blueprint <- case parseBlueprintJSON bytes of
        Right bp -> pure bp
        Left err -> do
            hPutStrLn stderr ("BlueprintParseError: " <> path <> ": " <> err)
            exitWith (ExitFailure 1)
    hashes <- case Aeson.eitherDecode bytes of
        Right jsonValue -> pure (blueprintHashes jsonValue)
        Left err -> do
            hPutStrLn stderr ("BlueprintParseError: " <> path <> ": " <> err)
            exitWith (ExitFailure 1)
    let title = preambleTitle (blueprintPreamble blueprint)
        indexed = [(sh, blueprint, title) | sh <- hashes]
        fallback = [(blueprint, title) | null hashes]
    pure (indexed, fallback)

blueprintHashes :: Aeson.Value -> [ScriptHash]
blueprintHashes (Aeson.Object root) =
    case KeyMap.lookup (Key.fromString "validators") root of
        Just (Aeson.Array validators) ->
            mapMaybe validatorHash (toList validators)
        _ -> []
  where
    validatorHash (Aeson.Object validator) = do
        Aeson.String raw <- KeyMap.lookup (Key.fromString "hash") validator
        scriptHashFromHex raw
    validatorHash _ = Nothing
blueprintHashes _ = []

scriptHashFromHex :: Text -> Maybe ScriptHash
scriptHashFromHex raw = do
    bytes <-
        either (const Nothing) Just $
            Base16.decode (TextEncoding.encodeUtf8 (Text.toLower raw))
    if BS.length bytes == 28
        then ScriptHash <$> hashFromBytes bytes
        else Nothing

enrichBlueprintTurtle ::
    BlueprintRegistry ->
    BS.ByteString ->
    IO BS.ByteString
enrichBlueprintTurtle index ttlBytes = do
    let ttlText = TextEncoding.decodeUtf8With lenientDecode ttlBytes
        graph = parseCanonicalTurtle ttlText
        decorations = blueprintDecorations index graph ttlText
    pure $
        if null decorations
            then ttlBytes
            else
                ttlBytes
                    <> ensureTrailingNewline ttlBytes
                    <> TextEncoding.encodeUtf8
                        ( Text.intercalate "\n" $
                            [ "#"
                            , "# Blueprint typed decode."
                            , "#"
                            , ""
                            ]
                                <> decorations
                        )

blueprintDecorations ::
    BlueprintRegistry ->
    TurtleGraph ->
    Text ->
    [Text]
blueprintDecorations index graph fullText =
    concatMap decorate (Map.toList (tgBlocks graph))
  where
    decorate (outSubj, outBlock)
        | not ("cardano:Output" `Text.isInfixOf` outBlock) = []
        | otherwise =
            case (objectFor "cardano:atAddress" outBlock, objectFor "cardano:hasDatum" outBlock) of
                (Just addr, Just datumSubj) ->
                    decorateDatum outSubj addr datumSubj
                _ -> []

    decorateDatum _outSubj addr datumSubj = fromMaybe [] $ do
        scriptHash <- outputScriptHash graph addr
        datumBlock <- Map.lookup datumSubj (tgBlocks graph)
        rawHex <- literalFor "cardano:hasRawBytes" datumBlock
        rawBytes <-
            either (const Nothing) Just $
                Base16.decode (TextEncoding.encodeUtf8 rawHex)
        datum <- decodeDatumBytes rawBytes
        case decodeDatumFromRegistry index scriptHash datum of
            Decoded openValue blueprint ->
                let rendered = renderTypedDatum datumSubj blueprint openValue
                 in if any (`Text.isInfixOf` fullText) (typedPredicates rendered)
                        then Just []
                        else Just rendered
            DecodeFailed err ->
                Just [datumSubj <> " cardano:decodeError " <> turtleString (Text.pack (show err)) <> " .", ""]
            NoBlueprintRegistered -> Just []

decodeDatumFromRegistry ::
    BlueprintRegistry ->
    ScriptHash ->
    Data ConwayEra ->
    BlueprintDecodeResult
decodeDatumFromRegistry BlueprintRegistry{registryIndexed, registryFallback} scriptHash datum =
    case decodeDatumForScriptHash registryIndexed scriptHash datum of
        NoBlueprintRegistered ->
            fallbackDecode registryFallback
        result -> result
  where
    fallbackDecode fallbacks =
        let results =
                [ decodeDatumForScriptHash [(scriptHash, blueprint, title)] scriptHash datum
                | (blueprint, title) <- fallbacks
                ]
         in case [result | result@(Decoded _ _) <- results] of
                result : _ -> result
                [] -> case [result | result@(DecodeFailed _) <- results] of
                    result : _ -> result
                    [] -> NoBlueprintRegistered

typedPredicates :: [Text] -> [Text]
typedPredicates =
    mapMaybe
        ( \line ->
            case Text.words line of
                (_subj : predName : _) | ":" `Text.isPrefixOf` predName -> Just predName
                _ -> Nothing
        )

outputScriptHash :: TurtleGraph -> Text -> Maybe ScriptHash
outputScriptHash graph addr = do
    addrBlock <- Map.lookup addr (tgBlocks graph)
    paymentCred <- objectFor "cardano:hasPaymentCredential" addrBlock
    credBlock <- Map.lookup paymentCred (tgBlocks graph)
    ident <- objectFor "cardano:hasIdentifier" credBlock
    scriptHashFromIdentifier ident

scriptHashFromIdentifier :: Text -> Maybe ScriptHash
scriptHashFromIdentifier ident =
    let prefix = "<urn:cardano:id:PaymentScript:"
     in if prefix `Text.isPrefixOf` ident && ">" `Text.isSuffixOf` ident
            then scriptHashFromHex (Text.dropEnd 1 (Text.drop (Text.length prefix) ident))
            else Nothing

decodeDatumBytes :: BS.ByteString -> Maybe (Data ConwayEra)
decodeDatumBytes raw =
    either (const Nothing) Just $
        decodeFullDecoder
            (natVersion @11)
            "Conway datum"
            (decCBOR @(Data ConwayEra))
            (LBS.fromStrict raw)

renderTypedDatum :: Text -> Blueprint -> OpenValue -> [Text]
renderTypedDatum datumSubj blueprint openValue =
    case openValue of
        OpenObject fields ->
            concatMap
                (uncurry (renderField datumSubj base ctor))
                (Map.toAscList fields)
        _ -> []
  where
    base = bnodeBase datumSubj
    ctor = topDatumConstructorTitle blueprint

renderField :: Text -> Text -> Text -> Text -> OpenValue -> [Text]
renderField parent base ctor fieldName openValue =
    let fieldBase = base <> "_" <> fieldName
        (obj, extra) = renderOpenObject fieldBase openValue
     in [parent <> " " <> blueprintPredicate ctor fieldName <> " " <> obj <> " ."]
            <> extra
            <> [""]

renderOpenObject :: Text -> OpenValue -> (Text, [Text])
renderOpenObject _base (OpenInteger n) = (Text.pack (show n), [])
renderOpenObject _base (OpenText t) = (turtleString t, [])
renderOpenObject base (OpenBytes hex) =
    let subject = "_:" <> base
     in ( subject
        ,
            [ subject <> " a cardano:Identifier ;"
            , "  cardano:leafType \"Bytes\" ;"
            , "  cardano:bytesHex " <> turtleString hex <> " ."
            ]
        )
renderOpenObject base (OpenObject fields) =
    let subject = "_:" <> base
        triples =
            concatMap
                (uncurry (renderField subject base "_0"))
                (Map.toAscList fields)
     in (subject, triples)
renderOpenObject base (OpenArray _values) =
    ("_:" <> base, [])

topDatumConstructorTitle :: Blueprint -> Text
topDatumConstructorTitle blueprint =
    case [(v, arg) | v <- blueprintValidators blueprint, Just arg <- [validatorDatum v]] of
        [] -> "_0"
        (validator, blueprintArg) : _ ->
            case schemaTitle (resolvedSchema blueprint blueprintArg) of
                Just title -> title
                Nothing -> fromMaybe "_0" (validatorTitle validator)

resolvedSchema :: Blueprint -> BlueprintArgument -> BlueprintSchema
resolvedSchema blueprint blueprintArg =
    case resolveBlueprintSchema blueprint (argumentSchema blueprintArg) of
        Right schema -> schema
        Left _ -> argumentSchema blueprintArg

blueprintPredicate :: Text -> Text -> Text
blueprintPredicate ctor fieldName = ":" <> ctor <> "_" <> fieldName

bnodeBase :: Text -> Text
bnodeBase subject =
    fromMaybe subject (Text.stripPrefix "_:" subject)

----------------------------------------------------------------------
-- cq-rdf shacl
----------------------------------------------------------------------

shaclCommand :: ShaclOptions -> IO ()
shaclCommand ShaclOptions{shaclShapes, shaclOut, shaclSeverity} = do
    dataTtl <- BS.hGetContents stdin
    shapeFiles <- shapeFilesIn shaclShapes
    withTempFile "cq-rdf-data" ".ttl" $ \dataPath ->
        withTempFile "cq-rdf-shapes" ".ttl" $ \shapesPath -> do
            BS.writeFile dataPath dataTtl
            shapeBytes <- fmap BS.concat (traverse BS.readFile shapeFiles)
            BS.writeFile shapesPath shapeBytes
            (code, report, err) <-
                readProcessWithExitCode
                    "shacl"
                    ["validate", "--shapes", shapesPath, "--data", dataPath]
                    ""
            unless (null err) (hPutStrLn stderr err)
            let failed = reportFails shaclSeverity report
                reportBytes =
                    if not failed && "sh:conforms  true" `List.isInfixOf` report
                        then BS.empty
                        else BS8.pack report
            writeOutput shaclOut reportBytes
            case code of
                ExitFailure n -> exitWith (ExitFailure n)
                ExitSuccess ->
                    when failed $
                        exitWith (ExitFailure 1)

shapeFilesIn :: FilePath -> IO [FilePath]
shapeFilesIn dir = do
    exists <- doesDirectoryExist dir
    unless exists $ do
        hPutStrLn stderr ("SHACL shapes directory does not exist: " <> dir)
        exitWith (ExitFailure 1)
    names <- listDirectory dir
    pure
        [ dir </> name
        | name <- List.sort names
        , ".shacl.ttl" `List.isSuffixOf` name
        ]

reportFails :: ShaclSeverity -> String -> Bool
reportFails severity report =
    case severity of
        ShaclViolationOnly ->
            "sh:Violation" `List.isInfixOf` report
                || "http://www.w3.org/ns/shacl#Violation" `List.isInfixOf` report
                || "Conforms: false" `List.isInfixOf` report
        ShaclWarningAndViolation ->
            reportFails ShaclViolationOnly report
                || "sh:Warning" `List.isInfixOf` report
                || "http://www.w3.org/ns/shacl#Warning" `List.isInfixOf` report

parseFormat :: String -> Either EmitError EmitFormat
parseFormat = \case
    "turtle" -> Right Turtle
    "json-ld" -> Right JsonLd
    other -> Left (UnknownFormat (Text.pack other))

{- | Resolve the tx's inputs against the in-memory lattice via the
standard 'Resolver' chain. Missing entries fall through as
unresolved (same semantics the on-disk closure resolver had in issue
112, now without the disk roundtrip).
-}
resolveAgainstLattice :: Map TxId ConwayTx -> ConwayTx -> IO ResolvedUTxO
resolveAgainstLattice lattice tx = do
    let r = inMemoryResolver lattice
    (resolved, _unresolved) <- resolveChain [r] (collectInputs tx)
    pure resolved

{- | A 'Resolver' that looks each input up in the in-memory
lattice keyed by 'TxId'. Out-of-range output indices and missing
parents are dropped, matching the resolver-chain contract.
-}
inMemoryResolver :: Map TxId ConwayTx -> Resolver
inMemoryResolver lattice =
    Resolver
        { resolverName = "in-memory-lattice"
        , resolveInputs = \inputs ->
            pure $
                Map.fromList
                    [ (txIn, output)
                    | txIn <- Set.toList inputs
                    , Just output <- [resolveOne lattice txIn]
                    ]
        }

{- | Resolve a single 'TxIn' against the in-memory lattice. Returns
'Nothing' if the parent tx isn't indexed or the index is out of
range.
-}
resolveOne :: Map TxId ConwayTx -> TxIn -> Maybe (TxOut ConwayEra)
resolveOne lattice (TxIn parentTxId (TxIx ix)) = do
    parentTx <- Map.lookup parentTxId lattice
    let outs = toList (parentTx ^. bodyTxL . outputsTxBodyL)
    indexOutputs outs (fromIntegral ix)

indexOutputs :: [a] -> Int -> Maybe a
indexOutputs xs n
    | n < 0 = Nothing
    | otherwise = go xs n
  where
    go [] _ = Nothing
    go (x : _) 0 = Just x
    go (_ : rest) k = go rest (k - 1)

{- | Collect every 'TxIn' the body references: spending inputs,
reference inputs, collateral inputs.
-}
collectInputs :: ConwayTx -> Set TxIn
collectInputs tx =
    let body = tx ^. bodyTxL
     in (body ^. inputsTxBodyL)
            <> (body ^. referenceInputsTxBodyL)
            <> (body ^. collateralInputsTxBodyL)

{- | Load the operator-entity list, the blueprint index, AND the
overlay Turtle bytes from a rules file. The overlay bytes are
inlined into the joint Turtle output; the entity list drives the
credential lookup; the blueprint index (#50) drives typed
emission for per-output inline datums, datum witnesses, and
per-purpose redeemers.
-}
loadOverlayAndEntitiesOrExit ::
    FilePath ->
    IO ([EntityDecl], [(ScriptHash, Blueprint, Text)], BS.ByteString)
loadOverlayAndEntitiesOrExit path = do
    result <- loadRulesFile path
    case result of
        Right
            res@RulesLoadResult
                { rulesOverlayTurtle
                , rulesBlueprints
                , rulesWarnings
                } -> do
                mapM_ (hPutStrLn stderr . renderRulesLoadWarning) rulesWarnings
                pure
                    ( rulesEntities res
                    , rulesBlueprints
                    , rulesOverlayTurtle
                    )
        Left err -> do
            hPutStrLn stderr (renderRulesLoadError err)
            exitWith (ExitFailure 1)

{- | Either project an 'EmitError' to a stderr line + exit 1, or
pass through a successful value.
-}
exitOnEmitError :: Either EmitError a -> IO a
exitOnEmitError = \case
    Right a -> pure a
    Left e -> do
        hPutStrLn stderr (renderEmitError e)
        exitWith (ExitFailure 1)

{- | Walk the emitted graph's body sections and project each
@cardano:decodeError@ literal triple onto a single-line stderr
warning of the form
@warning: blueprint decode failed for \<subject\>: \<error\>@.
-}
decodeErrorWarnings :: EmittedGraph -> [String]
decodeErrorWarnings g =
    [ "warning: blueprint decode failed for "
        <> renderSubject (subjectBlockSubject block)
        <> ": "
        <> Text.unpack msg
    | section <- graphBody g
    , block <- sectionBlocks section
    , (PIri predIri, OStringLit msg) <- subjectBlockPredicates block
    , predIri == "cardano:decodeError"
    ]

-- | Render a 'Subject' in its native Turtle surface form.
renderSubject :: Subject -> String
renderSubject = \case
    SBnode (BnodeName name) -> "_:" <> Text.unpack name
    SIri iri -> Text.unpack iri
