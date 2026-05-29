{-# LANGUAGE DataKinds #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TypeApplications #-}

{- |
Module      : Cardano.Tx.Graph.Emit.GovAction
Description : Typed RDF walker for Conway governance actions.
License     : Apache-2.0

Private emitter helper for Conway governance-action variants that
carry queryable typed payloads beyond the common proposal shell.
-}
module Cardano.Tx.Graph.Emit.GovAction (
    emitTypedGovActionTree,
) where

import Data.ByteString (ByteString)
import Data.ByteString.Base16 qualified as Base16
import Data.Map.Strict qualified as Map
import Data.Ratio (denominator, numerator)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as TextEncoding

import Lens.Micro ((^.))

import Cardano.Crypto.Hash (hashToBytes)
import Cardano.Ledger.Api.PParams (
    PParamsUpdate,
    ppuA0L,
    ppuCoinsPerUTxOByteL,
    ppuCollateralPercentageL,
    ppuCostModelsL,
    ppuEMaxL,
    ppuKeyDepositL,
    ppuMaxBBSizeL,
    ppuMaxBHSizeL,
    ppuMaxBlockExUnitsL,
    ppuMaxCollateralInputsL,
    ppuMaxTxExUnitsL,
    ppuMaxTxSizeL,
    ppuMaxValSizeL,
    ppuMinPoolCostL,
    ppuNOptL,
    ppuPoolDepositL,
    ppuPricesL,
    ppuRhoL,
    ppuTauL,
    ppuTxFeeFixedL,
    ppuTxFeePerByteL,
 )
import Cardano.Ledger.BaseTypes (
    BoundedRational (unboundRational),
    EpochInterval (..),
    ProtVer (..),
    StrictMaybe (SJust, SNothing),
    UnitInterval,
    urlToText,
 )
import Cardano.Ledger.Binary (getVersion)
import Cardano.Ledger.Coin (Coin (..), CoinPerByte (..))
import Cardano.Ledger.Compactible (fromCompact)
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.Governance (
    Anchor (..),
    Constitution (..),
    GovAction (..),
    GovActionId (..),
    GovActionIx (..),
    GovActionPurpose (..),
    GovPurposeId (..),
 )
import Cardano.Ledger.Conway.PParams (
    DRepVotingThresholds (..),
    PoolVotingThresholds (..),
    ppuCommitteeMaxTermLengthL,
    ppuCommitteeMinSizeL,
    ppuDRepActivityL,
    ppuDRepDepositL,
    ppuDRepVotingThresholdsL,
    ppuGovActionDepositL,
    ppuGovActionLifetimeL,
    ppuMinFeeRefScriptCostPerByteL,
    ppuPoolVotingThresholdsL,
 )
import Cardano.Ledger.Credential (Credential (KeyHashObj, ScriptHashObj))
import Cardano.Ledger.Hashes (
    KeyHash (..),
    ScriptHash (..),
    extractHash,
 )
import Cardano.Ledger.Keys (
    KeyRole (ColdCommitteeRole),
 )
import Cardano.Ledger.Plutus.ExUnits (
    ExUnits (..),
    Prices (..),
 )
import Cardano.Ledger.TxIn (TxId (..))
import Cardano.Slotting.Slot (EpochNo (..))

import Cardano.Tx.Graph.Emit.Lookup (
    BnodeName (..),
    LookupTable,
    identifierIri,
    textIdentifierIri,
 )
import Cardano.Tx.Graph.Emit.Monad (Emit, introduce, tellTriple)
import Cardano.Tx.Graph.Emit.Triple (
    Object (..),
    Predicate (..),
    Subject (..),
    Triple (..),
 )
import Cardano.Tx.Graph.Emit.Vocab (VocabTerm (..), vocabCurie)
import Cardano.Tx.Graph.Rules.Load (LeafType (..))

type ResolveIdent =
    LookupTable -> LeafType -> ByteString -> Emit Object

{- | Emit a typed governance-action tree for the covered Conway
constructors. Variants still intentionally modeled by another
walker or only by the proposal datum fallback return 'Nothing'.
-}
emitTypedGovActionTree ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    BnodeName ->
    GovAction ConwayEra ->
    Maybe (Emit ())
emitTypedGovActionTree lookupTbl resolveIdent proposalBnode rootBnode = \case
    ParameterChange prior params guardPolicy ->
        Just $
            emitParameterChange
                lookupTbl
                resolveIdent
                proposalBnode
                rootBnode
                prior
                params
                guardPolicy
    HardForkInitiation prior protVer ->
        Just $
            emitHardForkInitiation
                lookupTbl
                proposalBnode
                rootBnode
                prior
                protVer
    UpdateCommittee prior removed added quorum ->
        Just $
            emitUpdateCommittee
                lookupTbl
                resolveIdent
                proposalBnode
                rootBnode
                prior
                removed
                added
                quorum
    NewConstitution prior constitution ->
        Just $
            emitNewConstitution
                lookupTbl
                resolveIdent
                proposalBnode
                rootBnode
                prior
                constitution
    _ -> Nothing

emitParameterChange ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    BnodeName ->
    StrictMaybe (GovPurposeId 'PParamUpdatePurpose) ->
    PParamsUpdate ConwayEra ->
    StrictMaybe ScriptHash ->
    Emit ()
emitParameterChange
    lookupTbl
    resolveIdent
    proposalBnode
    rootBnode
    prior
    params
    guardPolicy = do
        govActionHeader proposalBnode rootBnode TermParameterChange
        emitPriorAction lookupTbl rootBnode prior
        emitProtocolParamUpdate rootBnode params
        case guardPolicy of
            SNothing -> pure ()
            SJust (ScriptHash h) -> do
                guardObj <-
                    resolveIdent lookupTbl LtScriptHash (hashToBytes h)
                tellObj rootBnode TermHasGuardPolicy guardObj

emitHardForkInitiation ::
    LookupTable ->
    BnodeName ->
    BnodeName ->
    StrictMaybe (GovPurposeId 'HardForkPurpose) ->
    ProtVer ->
    Emit ()
emitHardForkInitiation lookupTbl proposalBnode rootBnode prior protVer = do
    govActionHeader proposalBnode rootBnode TermHardForkInitiation
    emitPriorAction lookupTbl rootBnode prior
    let versionBnode = childBnode rootBnode "ProtocolVersion"
    tellObj rootBnode TermHasProtocolVersion (OBnode versionBnode)
    tellType versionBnode TermProtocolVersion
    emitProtocolVersion versionBnode protVer

emitUpdateCommittee ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    BnodeName ->
    StrictMaybe (GovPurposeId 'CommitteePurpose) ->
    Set.Set (Credential ColdCommitteeRole) ->
    Map.Map (Credential ColdCommitteeRole) EpochNo ->
    UnitInterval ->
    Emit ()
emitUpdateCommittee
    lookupTbl
    resolveIdent
    proposalBnode
    rootBnode
    prior
    removed
    added
    quorum = do
        govActionHeader proposalBnode rootBnode TermUpdateCommittee
        emitPriorAction lookupTbl rootBnode prior
        tellText rootBnode TermHasNewQuorum (renderRational quorum)
        mapM_
            (emitRemovedMember lookupTbl resolveIdent rootBnode)
            (Set.toAscList removed)
        mapM_
            (emitAddedMember lookupTbl resolveIdent rootBnode)
            (zip [1 :: Int ..] (Map.toAscList added))

emitNewConstitution ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    BnodeName ->
    StrictMaybe (GovPurposeId 'ConstitutionPurpose) ->
    Constitution ConwayEra ->
    Emit ()
emitNewConstitution
    lookupTbl
    resolveIdent
    proposalBnode
    rootBnode
    prior
    Constitution{..} = do
        govActionHeader proposalBnode rootBnode TermNewConstitution
        emitPriorAction lookupTbl rootBnode prior
        let constitutionBnode = childBnode rootBnode "Constitution"
        tellObj rootBnode TermHasConstitution (OBnode constitutionBnode)
        tellType constitutionBnode TermConstitution
        emitAnchor
            lookupTbl
            resolveIdent
            constitutionBnode
            (childBnode constitutionBnode "Anchor")
            constitutionAnchor
        case constitutionGuardrailsScriptHash of
            SNothing -> pure ()
            SJust (ScriptHash h) -> do
                guardObj <-
                    resolveIdent lookupTbl LtScriptHash (hashToBytes h)
                tellObj constitutionBnode TermHasGuardrailScript guardObj

emitProtocolParamUpdate ::
    BnodeName ->
    PParamsUpdate ConwayEra ->
    Emit ()
emitProtocolParamUpdate rootBnode params = do
    let updateBnode = childBnode rootBnode "ProtocolParamUpdate"
    tellObj rootBnode TermHasProtocolParamUpdate (OBnode updateBnode)
    tellType updateBnode TermProtocolParamUpdate
    emitMaybeCoinPerByte updateBnode TermHasMinFeeA $
        params ^. ppuTxFeePerByteL @ConwayEra
    emitMaybeCoin updateBnode TermHasMinFeeB $
        params ^. ppuTxFeeFixedL @ConwayEra
    emitMaybeIntegral updateBnode TermHasMaxBlockBodySize $
        params ^. ppuMaxBBSizeL @ConwayEra
    emitMaybeIntegral updateBnode TermHasMaxTxSize $
        params ^. ppuMaxTxSizeL @ConwayEra
    emitMaybeIntegral updateBnode TermHasMaxBlockHeaderSize $
        params ^. ppuMaxBHSizeL @ConwayEra
    emitMaybeCoin updateBnode TermHasKeyDeposit $
        params ^. ppuKeyDepositL @ConwayEra
    emitMaybeCoin updateBnode TermHasPoolDeposit $
        params ^. ppuPoolDepositL @ConwayEra
    emitMaybeEpochInterval updateBnode TermHasMaxEpoch $
        params ^. ppuEMaxL @ConwayEra
    emitMaybeIntegral updateBnode TermHasNOpt $
        params ^. ppuNOptL @ConwayEra
    emitMaybeRational updateBnode TermHasPoolPledgeInfluence $
        params ^. ppuA0L @ConwayEra
    emitMaybeRational updateBnode TermHasExpansionRate $
        params ^. ppuRhoL @ConwayEra
    emitMaybeRational updateBnode TermHasTreasuryGrowthRate $
        params ^. ppuTauL @ConwayEra
    emitMaybeCoin updateBnode TermHasMinPoolCost $
        params ^. ppuMinPoolCostL @ConwayEra
    emitMaybeCoinPerByte updateBnode TermHasAdaPerUtxoByte $
        params ^. ppuCoinsPerUTxOByteL @ConwayEra
    emitMaybeText updateBnode TermHasCostModels (Text.pack . show) $
        params ^. ppuCostModelsL @ConwayEra
    emitMaybePrices updateBnode $
        params ^. ppuPricesL @ConwayEra
    emitMaybeExUnits updateBnode TermHasMaxTxExUnits "MaxTxExUnits" $
        params ^. ppuMaxTxExUnitsL @ConwayEra
    emitMaybeExUnits updateBnode TermHasMaxBlockExUnits "MaxBlockExUnits" $
        params ^. ppuMaxBlockExUnitsL @ConwayEra
    emitMaybeIntegral updateBnode TermHasMaxValueSize $
        params ^. ppuMaxValSizeL @ConwayEra
    emitMaybeIntegral updateBnode TermHasCollateralPercentage $
        params ^. ppuCollateralPercentageL @ConwayEra
    emitMaybeIntegral updateBnode TermHasMaxCollateralInputs $
        params ^. ppuMaxCollateralInputsL @ConwayEra
    emitMaybePoolVotingThresholds updateBnode $
        params ^. ppuPoolVotingThresholdsL @ConwayEra
    emitMaybeDRepVotingThresholds updateBnode $
        params ^. ppuDRepVotingThresholdsL @ConwayEra
    emitMaybeIntegral updateBnode TermHasCommitteeMinSize $
        params ^. ppuCommitteeMinSizeL @ConwayEra
    emitMaybeEpochInterval updateBnode TermHasCommitteeMaxTermLength $
        params ^. ppuCommitteeMaxTermLengthL @ConwayEra
    emitMaybeEpochInterval updateBnode TermHasGovActionLifetime $
        params ^. ppuGovActionLifetimeL @ConwayEra
    emitMaybeCoin updateBnode TermHasGovActionDeposit $
        params ^. ppuGovActionDepositL @ConwayEra
    emitMaybeCoin updateBnode TermHasDRepDeposit $
        params ^. ppuDRepDepositL @ConwayEra
    emitMaybeEpochInterval updateBnode TermHasDRepActivity $
        params ^. ppuDRepActivityL @ConwayEra
    emitMaybeRational updateBnode TermHasMinFeeRefScriptCoinsPerByte $
        params ^. ppuMinFeeRefScriptCostPerByteL @ConwayEra

emitMaybeExUnits ::
    BnodeName ->
    VocabTerm ->
    Text ->
    StrictMaybe ExUnits ->
    Emit ()
emitMaybeExUnits _ _ _ SNothing = pure ()
emitMaybeExUnits parentBnode predicate suffix (SJust (ExUnits memory steps)) = do
    let bnode = childBnode parentBnode suffix
    tellObj parentBnode predicate (OBnode bnode)
    tellType bnode TermExUnits
    tellInt bnode TermHasMemory (toInteger memory)
    tellInt bnode TermHasSteps (toInteger steps)

emitMaybePrices :: BnodeName -> StrictMaybe Prices -> Emit ()
emitMaybePrices _ SNothing = pure ()
emitMaybePrices parentBnode (SJust Prices{..}) = do
    let bnode = childBnode parentBnode "ExecutionCosts"
    tellObj parentBnode TermHasExecutionCosts (OBnode bnode)
    tellType bnode TermExUnitPrices
    tellText bnode TermHasPriceMemory (renderRational prMem)
    tellText bnode TermHasPriceSteps (renderRational prSteps)

emitMaybePoolVotingThresholds ::
    BnodeName ->
    StrictMaybe PoolVotingThresholds ->
    Emit ()
emitMaybePoolVotingThresholds _ SNothing = pure ()
emitMaybePoolVotingThresholds parentBnode (SJust PoolVotingThresholds{..}) = do
    let bnode = childBnode parentBnode "PoolVotingThresholds"
    tellObj parentBnode TermHasPoolVotingThresholds (OBnode bnode)
    tellType bnode TermPoolVotingThresholds
    tellText bnode TermHasMotionNoConfidence $
        renderRational pvtMotionNoConfidence
    tellText bnode TermHasCommitteeNormal $
        renderRational pvtCommitteeNormal
    tellText bnode TermHasCommitteeNoConfidence $
        renderRational pvtCommitteeNoConfidence
    tellText bnode TermHasHardForkInitiation $
        renderRational pvtHardForkInitiation
    tellText bnode TermHasPPSecurityGroup $
        renderRational pvtPPSecurityGroup

emitMaybeDRepVotingThresholds ::
    BnodeName ->
    StrictMaybe DRepVotingThresholds ->
    Emit ()
emitMaybeDRepVotingThresholds _ SNothing = pure ()
emitMaybeDRepVotingThresholds parentBnode (SJust DRepVotingThresholds{..}) = do
    let bnode = childBnode parentBnode "DRepVotingThresholds"
    tellObj parentBnode TermHasDRepVotingThresholds (OBnode bnode)
    tellType bnode TermDRepVotingThresholds
    tellText bnode TermHasMotionNoConfidence $
        renderRational dvtMotionNoConfidence
    tellText bnode TermHasCommitteeNormal $
        renderRational dvtCommitteeNormal
    tellText bnode TermHasCommitteeNoConfidence $
        renderRational dvtCommitteeNoConfidence
    tellText bnode TermHasUpdateToConstitution $
        renderRational dvtUpdateToConstitution
    tellText bnode TermHasHardForkInitiation $
        renderRational dvtHardForkInitiation
    tellText bnode TermHasPPNetworkGroup $
        renderRational dvtPPNetworkGroup
    tellText bnode TermHasPPEconomicGroup $
        renderRational dvtPPEconomicGroup
    tellText bnode TermHasPPTechnicalGroup $
        renderRational dvtPPTechnicalGroup
    tellText bnode TermHasPPGovGroup $
        renderRational dvtPPGovGroup
    tellText bnode TermHasTreasuryWithdrawal $
        renderRational dvtTreasuryWithdrawal

emitRemovedMember ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    Credential ColdCommitteeRole ->
    Emit ()
emitRemovedMember lookupTbl resolveIdent rootBnode cred = do
    credObj <- resolveCommitteeColdCredential lookupTbl resolveIdent cred
    tellObj rootBnode TermRemovesMember credObj

emitAddedMember ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    (Int, (Credential ColdCommitteeRole, EpochNo)) ->
    Emit ()
emitAddedMember lookupTbl resolveIdent rootBnode (ix, (cred, EpochNo epoch)) = do
    let additionBnode =
            childBnode rootBnode ("CommitteeAddition" <> Text.pack (show ix))
    credObj <- resolveCommitteeColdCredential lookupTbl resolveIdent cred
    tellObj rootBnode TermAddsMember (OBnode additionBnode)
    tellType additionBnode TermCommitteeAddition
    tellObj additionBnode TermHasIdentifier credObj
    tellInt additionBnode TermTermLimit (fromIntegral epoch)

emitAnchor ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    BnodeName ->
    Anchor ->
    Emit ()
emitAnchor lookupTbl resolveIdent parentBnode anchorBnode (Anchor url dataHash) = do
    hashObj <-
        resolveIdent
            lookupTbl
            LtAnchorDataHash
            (hashToBytes (extractHash dataHash))
    tellObj parentBnode TermHasAnchor (OBnode anchorBnode)
    tellType anchorBnode TermAnchor
    tellText anchorBnode TermAnchorUrl (urlToText url)
    tellObj anchorBnode TermAnchorHash hashObj

emitProtocolVersion :: BnodeName -> ProtVer -> Emit ()
emitProtocolVersion bnode ProtVer{..} = do
    tellInt bnode TermHasMajorVersion (getVersion @Integer pvMajor)
    tellInt bnode TermHasMinorVersion (toInteger pvMinor)

emitPriorAction ::
    LookupTable ->
    BnodeName ->
    StrictMaybe (GovPurposeId p) ->
    Emit ()
emitPriorAction lookupTbl rootBnode = \case
    SNothing -> pure ()
    SJust (GovPurposeId actionId) -> do
        actionObj <- emitGovActionIdBlock lookupTbl actionId
        tellObj rootBnode TermHasPriorAction actionObj

emitGovActionIdBlock :: LookupTable -> GovActionId -> Emit Object
emitGovActionIdBlock lookupTbl (GovActionId (TxId safeHash) (GovActionIx ix)) = do
    let txIdBytes = hashToBytes (extractHash safeHash)
        token = hexText txIdBytes <> ":" <> Text.pack (show ix)
        govActionIri = textIdentifierIri LtGovActionId token
        govActionSubj = SIri govActionIri
    txIdObj <- resolveTxId lookupTbl txIdBytes
    introduce govActionSubj $ do
        tellTriple (Triple govActionSubj PRdfType (OIri (vocabCurie TermGovActionId)))
        tellTriple (Triple govActionSubj PRdfType (OIri (vocabCurie TermIdentifier)))
        tellTriple
            ( Triple
                govActionSubj
                (PIri (vocabCurie TermLeafType))
                (OStringLit "GovActionId")
            )
        tellTriple
            ( Triple
                govActionSubj
                (PIri (vocabCurie TermBytesHex))
                (OStringLit token)
            )
        tellTriple
            (Triple govActionSubj (PIri (vocabCurie TermHasTxId)) txIdObj)
        tellTriple
            ( Triple
                govActionSubj
                (PIri (vocabCurie TermHasIndex))
                (OIntLit (fromIntegral ix))
            )
    pure (OIri govActionIri)

resolveTxId :: LookupTable -> ByteString -> Emit Object
resolveTxId _lookupTbl bytes = do
    let token = hexText bytes
        iri = identifierIri LtTxId bytes
        subj = SIri iri
    introduce subj $ do
        tellTriple (Triple subj PRdfType (OIri (vocabCurie TermIdentifier)))
        tellTriple
            (Triple subj (PIri (vocabCurie TermLeafType)) (OStringLit "TxId"))
        tellTriple
            (Triple subj (PIri (vocabCurie TermBytesHex)) (OStringLit token))
    pure (OIri iri)

resolveCommitteeColdCredential ::
    LookupTable ->
    ResolveIdent ->
    Credential ColdCommitteeRole ->
    Emit Object
resolveCommitteeColdCredential lookupTbl resolveIdent = \case
    KeyHashObj h -> resolveIdent lookupTbl CommitteeColdKey (keyHashBytes h)
    ScriptHashObj h ->
        resolveIdent lookupTbl CommitteeColdScript (scriptHashBytes h)

emitMaybeIntegral ::
    (Integral a) =>
    BnodeName ->
    VocabTerm ->
    StrictMaybe a ->
    Emit ()
emitMaybeIntegral _ _ SNothing = pure ()
emitMaybeIntegral bnode term (SJust n) =
    tellInt bnode term (fromIntegral n)

emitMaybeEpochInterval ::
    BnodeName ->
    VocabTerm ->
    StrictMaybe EpochInterval ->
    Emit ()
emitMaybeEpochInterval _ _ SNothing = pure ()
emitMaybeEpochInterval bnode term (SJust (EpochInterval n)) =
    tellInt bnode term (fromIntegral n)

emitMaybeCoin :: BnodeName -> VocabTerm -> StrictMaybe Coin -> Emit ()
emitMaybeCoin _ _ SNothing = pure ()
emitMaybeCoin bnode term (SJust coin) = tellCoin bnode term coin

emitMaybeCoinPerByte ::
    BnodeName ->
    VocabTerm ->
    StrictMaybe CoinPerByte ->
    Emit ()
emitMaybeCoinPerByte _ _ SNothing = pure ()
emitMaybeCoinPerByte bnode term (SJust (CoinPerByte compactCoin)) =
    tellCoin bnode term (fromCompact compactCoin)

emitMaybeRational ::
    (BoundedRational a) =>
    BnodeName ->
    VocabTerm ->
    StrictMaybe a ->
    Emit ()
emitMaybeRational _ _ SNothing = pure ()
emitMaybeRational bnode term (SJust r) =
    tellText bnode term (renderRational r)

emitMaybeText ::
    BnodeName ->
    VocabTerm ->
    (a -> Text) ->
    StrictMaybe a ->
    Emit ()
emitMaybeText _ _ _ SNothing = pure ()
emitMaybeText bnode term render (SJust x) =
    tellText bnode term (render x)

govActionHeader :: BnodeName -> BnodeName -> VocabTerm -> Emit ()
govActionHeader proposalBnode rootBnode classTerm = do
    tellObj proposalBnode TermHasGovAction (OBnode rootBnode)
    tellType rootBnode classTerm

tellType :: BnodeName -> VocabTerm -> Emit ()
tellType bnode term =
    tellTriple (Triple (SBnode bnode) PRdfType (OIri (vocabCurie term)))

tellObj :: BnodeName -> VocabTerm -> Object -> Emit ()
tellObj subj term obj =
    tellTriple (Triple (SBnode subj) (PIri (vocabCurie term)) obj)

tellText :: BnodeName -> VocabTerm -> Text -> Emit ()
tellText subj term txt =
    tellTriple
        (Triple (SBnode subj) (PIri (vocabCurie term)) (OStringLit txt))

tellInt :: BnodeName -> VocabTerm -> Integer -> Emit ()
tellInt subj term n =
    tellTriple
        (Triple (SBnode subj) (PIri (vocabCurie term)) (OIntLit n))

tellCoin :: BnodeName -> VocabTerm -> Coin -> Emit ()
tellCoin subj term (Coin n) =
    tellInt subj term (fromIntegral n)

renderRational :: (BoundedRational a) => a -> Text
renderRational r =
    let q = unboundRational r
     in Text.pack (show (numerator q) <> "/" <> show (denominator q))

childBnode :: BnodeName -> Text -> BnodeName
childBnode (BnodeName parent) suffix =
    BnodeName (parent <> suffix)

keyHashBytes :: KeyHash r -> ByteString
keyHashBytes (KeyHash h) = hashToBytes h

scriptHashBytes :: ScriptHash -> ByteString
scriptHashBytes (ScriptHash h) = hashToBytes h

hexText :: ByteString -> Text
hexText =
    TextEncoding.decodeLatin1 . Base16.encode
