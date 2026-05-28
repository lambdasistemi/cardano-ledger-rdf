{- |
Module      : Cardano.Tx.Graph.Emit.CatMergeCompositionSpec
Description : Cat-merge composability property for transaction Turtle.
License     : Apache-2.0

Issue #56 promotes content-addressed blank nodes to IRIs so two
independently emitted transaction responses can be concatenated and queried
without relying on parser-specific blank-node label behavior.
-}
module Cardano.Tx.Graph.Emit.CatMergeCompositionSpec (spec) where

import Data.ByteString qualified as BS
import Data.Map.Strict qualified as Map
import Data.Text qualified as Text
import System.Exit (ExitCode (..))
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)
import System.Process (readProcessWithExitCode)

import Cardano.Ledger.Api.Tx (bodyTxL)
import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Hashes (hashAnnotated)
import Cardano.Ledger.TxIn (TxId (..), TxIn (..))
import Lens.Micro ((^.))

import Cardano.Tx.Build (output, spend)
import Cardano.Tx.Graph.Emit (
    EmitFormat (..),
    emit,
    serialize,
 )
import Cardano.Tx.Ledger (ConwayTx)
import Fixtures.TxGraph.Helpers (
    TxBuilder (..),
    mkTx,
    stubTxOut,
 )
import Fixtures.TxGraph.S02_AliceBobAda qualified as S02

import Test.Hspec (
    Spec,
    describe,
    expectationFailure,
    it,
    shouldBe,
 )

spec :: Spec
spec =
    describe "Cardano.Tx.Graph.Emit cat-merge composition (#56)" $
        it "joins a spending input to the producing output across concatenated Turtle" $
            withSystemTempDirectory "tx-cat-merge" $ \dir -> do
                let mergedPath = dir </> "merged.ttl"
                    queryPath = dir </> "spent-output.rq"
                    merged = renderTx "cat-a" txA <> renderTx "cat-b" txB
                BS.writeFile mergedPath merged
                writeFile queryPath spentOutputQuery
                (ec, out, err) <-
                    readProcessWithExitCode
                        "arq"
                        [ "--data"
                        , mergedPath
                        , "--query"
                        , queryPath
                        , "--results=CSV"
                        ]
                        ""
                case ec of
                    ExitSuccess -> pure ()
                    ExitFailure n ->
                        expectationFailure $
                            "arq exited "
                                <> show n
                                <> "\nstdout:\n"
                                <> out
                                <> "\nstderr:\n"
                                <> err
                map (Text.dropWhileEnd (== '\r')) (Text.lines (Text.pack out))
                    `shouldBe` ["spentLovelace", "10000000"]

txA :: ConwayTx
txA = S02.tx

txB :: ConwayTx
txB =
    mkTx . TxBuilder $ do
        _ <- spend (TxIn (txIdOf txA) (TxIx 0))
        _ <- output (stubTxOut 9_825_000)
        pure ()

renderTx :: FilePath -> ConwayTx -> BS.ByteString
renderTx slug tx =
    case emit tx Map.empty [] [] of
        Left err -> error ("CatMergeCompositionSpec emit failed: " <> show err)
        Right g -> serialize Turtle slug g

txIdOf :: ConwayTx -> TxId
txIdOf tx = TxId (hashAnnotated (tx ^. bodyTxL))

spentOutputQuery :: String
spentOutputQuery =
    unlines
        [ "PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>"
        , "SELECT ?spentLovelace WHERE {"
        , "  ?bInput cardano:fromTxOutRef ?ref ."
        , "  ?ref cardano:hasTxId ?aTxId ; cardano:hasIndex ?i ."
        , "  ?aTxSubj cardano:hasTxId ?aTxId ; cardano:hasOutput ?aOutput ."
        , "  ?aOutput cardano:hasIndex ?i ; cardano:lovelace ?spentLovelace ."
        , "}"
        ]
