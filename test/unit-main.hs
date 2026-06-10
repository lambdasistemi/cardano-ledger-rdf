module Main (main) where

import Test.Hspec (hspec)

import Cardano.Tx.Doc.ExamplesSpec qualified as DocExamplesSpec
import Cardano.Tx.Graph.CqRdfExeSpec qualified as GraphCqRdfExeSpec
import Cardano.Tx.Graph.Emit.BlockfrostSampleSmokeSpec qualified as GraphEmitBlockfrostSampleSmokeSpec
import Cardano.Tx.Graph.Emit.BlueprintPredicateTraceabilitySpec qualified as GraphEmitBlueprintPredicateTraceabilitySpec
import Cardano.Tx.Graph.Emit.BlueprintSpec qualified as GraphEmitBlueprintSpec
import Cardano.Tx.Graph.Emit.BlueprintTypedFixtureSpec qualified as GraphEmitBlueprintTypedFixtureSpec
import Cardano.Tx.Graph.Emit.BlueprintWiringSpec qualified as GraphEmitBlueprintWiringSpec
import Cardano.Tx.Graph.Emit.BodyRootSpec qualified as GraphEmitBodyRootSpec
import Cardano.Tx.Graph.Emit.CatMergeCompositionSpec qualified as GraphEmitCatMergeCompositionSpec
import Cardano.Tx.Graph.Emit.CertVariantsSpec qualified as GraphEmitCertVariantsSpec
import Cardano.Tx.Graph.Emit.ExhaustivitySpec qualified as GraphEmitExhaustivitySpec
import Cardano.Tx.Graph.Emit.IdentifierLiteralSpec qualified as GraphEmitIdentifierLiteralSpec
import Cardano.Tx.Graph.Emit.InputSemanticSpec qualified as GraphEmitInputSemanticSpec
import Cardano.Tx.Graph.Emit.JsonLdEquivalenceSpec qualified as GraphEmitJsonLdEquivalenceSpec
import Cardano.Tx.Graph.Emit.LookupSpec qualified as GraphEmitLookupSpec
import Cardano.Tx.Graph.Emit.MintQuantitySpec qualified as GraphEmitMintQuantitySpec
import Cardano.Tx.Graph.Emit.MultiAssetListSpec qualified as GraphEmitMultiAssetListSpec
import Cardano.Tx.Graph.Emit.NativeScriptRefScriptSpec qualified as GraphEmitNativeScriptRefScriptSpec
import Cardano.Tx.Graph.Emit.NoStubViewSpec qualified as GraphEmitNoStubViewSpec
import Cardano.Tx.Graph.Emit.OutputDatumSpec qualified as GraphEmitOutputDatumSpec
import Cardano.Tx.Graph.Emit.OutputLovelaceSpec qualified as GraphEmitOutputLovelaceSpec
import Cardano.Tx.Graph.Emit.OutputScriptRefSpec qualified as GraphEmitOutputScriptRefSpec
import Cardano.Tx.Graph.Emit.ProposalSpec qualified as GraphEmitProposalSpec
import Cardano.Tx.Graph.Emit.ProposalVariantsSpec qualified as GraphEmitProposalVariantsSpec
import Cardano.Tx.Graph.Emit.ReproducibilitySpec qualified as GraphEmitReproducibilitySpec
import Cardano.Tx.Graph.Emit.RequiredSignersSpec qualified as GraphEmitRequiredSignersSpec
import Cardano.Tx.Graph.Emit.SubjectDeDupSpec qualified as GraphEmitSubjectDeDupSpec
import Cardano.Tx.Graph.Emit.TotalCollateralSpec qualified as GraphEmitTotalCollateralSpec
import Cardano.Tx.Graph.Emit.TurtleStringSpec qualified as GraphEmitTurtleStringSpec
import Cardano.Tx.Graph.Emit.VocabExportSpec qualified as GraphEmitVocabExportSpec
import Cardano.Tx.Graph.Emit.VocabTraceabilitySpec qualified as GraphEmitVocabTraceabilitySpec
import Cardano.Tx.Graph.Emit.VoteSpec qualified as GraphEmitVoteSpec
import Cardano.Tx.Graph.Emit.WithdrawalCanonicalSpec qualified as GraphEmitWithdrawalCanonicalSpec
import Cardano.Tx.Graph.Emit.WitnessSpec qualified as GraphEmitWitnessSpec
import Cardano.Tx.Graph.EmitGoldenSpec qualified as GraphEmitGoldenSpec
import Cardano.Tx.Graph.EmitMonadSpec qualified as GraphEmitMonadSpec
import Cardano.Tx.Graph.EmitSmokeSpec qualified as GraphEmitSmokeSpec
import Cardano.Tx.Graph.ResolveSpec qualified as GraphResolveSpec
import Cardano.Tx.Graph.ResolveWeb2Spec qualified as GraphResolveWeb2Spec
import Cardano.Tx.Graph.Rules.Load.BlueprintLoadSpec qualified as GraphRulesLoadBlueprintLoadSpec
import Cardano.Tx.Graph.Rules.LoadEntitiesSpec qualified as GraphRulesLoadEntitiesSpec
import Cardano.Tx.Graph.Rules.LoadExeSpec qualified as GraphRulesLoadExeSpec
import Cardano.Tx.Graph.Rules.LoadGoldenSpec qualified as GraphRulesLoadGoldenSpec
import Cardano.Tx.Graph.Rules.LoadImportsSpec qualified as GraphRulesLoadImportsSpec
import Cardano.Tx.Graph.Rules.LoadSmokeSpec qualified as GraphRulesLoadSmokeSpec
import Cardano.Tx.Graph.Rules.LoadTurtleSpec qualified as GraphRulesLoadTurtleSpec
import Cardano.Tx.Graph.Rules.LoadValidationSpec qualified as GraphRulesLoadValidationSpec
import Cardano.Tx.Graph.Rules.LoadYamlSpec qualified as GraphRulesLoadYamlSpec
import Cardano.Tx.Graph.ShapesAmaruMay2026Spec qualified as GraphShapesAmaruMay2026Spec
import Cardano.Tx.Graph.TxGraphExeSpec qualified as GraphTxGraphExeSpec
import Cardano.Tx.View.AssetFlowSpec qualified as ViewAssetFlowSpec
import Cardano.Tx.View.CliTreeEntitySpec qualified as ViewCliTreeEntitySpec
import Cardano.Tx.View.CliTreeGoldenSpec qualified as ViewCliTreeGoldenSpec
import Cardano.Tx.View.EntityOccurrencesSpec qualified as ViewEntityOccurrencesSpec
import Cardano.Tx.View.JsonLdSpec qualified as ViewJsonLdSpec
import Cardano.Tx.View.TurtleSpec qualified as ViewTurtleSpec
import Cardano.Tx.View.TxViewStdinSpec qualified as ViewTxViewStdinSpec

main :: IO ()
main = hspec $ do
    DocExamplesSpec.spec
    GraphCqRdfExeSpec.spec
    GraphEmitBlockfrostSampleSmokeSpec.spec
    GraphEmitBlueprintPredicateTraceabilitySpec.spec
    GraphEmitBlueprintSpec.spec
    GraphEmitBlueprintTypedFixtureSpec.spec
    GraphEmitBlueprintWiringSpec.spec
    GraphEmitBodyRootSpec.spec
    GraphEmitCatMergeCompositionSpec.spec
    GraphEmitCertVariantsSpec.spec
    GraphEmitExhaustivitySpec.spec
    GraphEmitIdentifierLiteralSpec.spec
    GraphEmitInputSemanticSpec.spec
    GraphEmitJsonLdEquivalenceSpec.spec
    GraphEmitLookupSpec.spec
    GraphEmitMintQuantitySpec.spec
    GraphEmitMultiAssetListSpec.spec
    GraphEmitNativeScriptRefScriptSpec.spec
    GraphEmitNoStubViewSpec.spec
    GraphEmitOutputDatumSpec.spec
    GraphEmitOutputLovelaceSpec.spec
    GraphEmitOutputScriptRefSpec.spec
    GraphEmitProposalSpec.spec
    GraphEmitProposalVariantsSpec.spec
    GraphEmitReproducibilitySpec.spec
    GraphEmitRequiredSignersSpec.spec
    GraphEmitSubjectDeDupSpec.spec
    GraphEmitTotalCollateralSpec.spec
    GraphEmitTurtleStringSpec.spec
    GraphEmitVocabExportSpec.spec
    GraphEmitVocabTraceabilitySpec.spec
    GraphEmitVoteSpec.spec
    GraphEmitWithdrawalCanonicalSpec.spec
    GraphEmitWitnessSpec.spec
    GraphEmitGoldenSpec.spec
    GraphEmitMonadSpec.spec
    GraphEmitSmokeSpec.spec
    GraphRulesLoadBlueprintLoadSpec.spec
    GraphRulesLoadEntitiesSpec.spec
    GraphRulesLoadExeSpec.spec
    GraphRulesLoadGoldenSpec.spec
    GraphRulesLoadImportsSpec.spec
    GraphRulesLoadSmokeSpec.spec
    GraphRulesLoadTurtleSpec.spec
    GraphRulesLoadValidationSpec.spec
    GraphRulesLoadYamlSpec.spec
    GraphResolveSpec.spec
    GraphResolveWeb2Spec.spec
    GraphShapesAmaruMay2026Spec.spec
    GraphTxGraphExeSpec.spec
    ViewAssetFlowSpec.spec
    ViewCliTreeGoldenSpec.spec
    ViewCliTreeEntitySpec.spec
    ViewEntityOccurrencesSpec.spec
    ViewJsonLdSpec.spec
    ViewTurtleSpec.spec
    ViewTxViewStdinSpec.spec
