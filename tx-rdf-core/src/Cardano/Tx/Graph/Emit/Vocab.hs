{- |
Module      : Cardano.Tx.Graph.Emit.Vocab
Description : Single-source-of-truth registry of vocab IRIs used by the body emitter.
License     : Apache-2.0

Private submodule of 'Cardano.Tx.Graph.Emit'. The projection
walker ('Cardano.Tx.Graph.Emit.Project') and the Turtle / JSON-LD
serializers route every emitted IRI through this registry; the
'Cardano.Tx.Graph.Emit.VocabTraceabilitySpec' (analyzer H1
closer) cross-checks the emitter output against
'allVocabTerms' + the fixture-local prefix.

Closes spec FR-009 + SC-005 (vocab traceability) for the
fixture-02 coverage shipped by T005. Future slices (T006-T010)
extend the enum as new leaves require new terms.
-}
module Cardano.Tx.Graph.Emit.Vocab (
    -- * Prefix bases
    cardanoPrefix,
    rdfsPrefix,
    rdfPrefix,
    xsdPrefix,
    owlPrefix,
    fixturePrefixBase,

    -- * Vocab term registry
    VocabTerm (..),
    vocabIri,
    vocabCurie,
    allVocabTerms,
) where

import Data.Text (Text)

-- | The kmaps Phase A @cardano:@ namespace base.
cardanoPrefix :: Text
cardanoPrefix =
    "https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#"

-- | The RDF Schema namespace.
rdfsPrefix :: Text
rdfsPrefix = "http://www.w3.org/2000/01/rdf-schema#"

{- | The core RDF namespace. Carries 'rdf:first', 'rdf:rest', and
'rdf:nil' — the list-cell primitives T104 emits when an output
carries a non-empty multi-asset value.
-}
rdfPrefix :: Text
rdfPrefix = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"

-- | The XML Schema namespace. Carries explicitly typed boolean literals.
xsdPrefix :: Text
xsdPrefix = "http://www.w3.org/2001/XMLSchema#"

{- | The OWL namespace. Phase 3 of epic 66 introduced the
@owl:Ontology@ manifest declaration at the top of every emitted
overlay; the joint serializer keeps the prefix line so the
overlay block embedded under the prefix header parses cleanly.
-}
owlPrefix :: Text
owlPrefix = "http://www.w3.org/2002/07/owl#"

{- | The fixture-local prefix base. The full @\@prefix :@ IRI is
@\<fixturePrefixBase\>\<slug\>#@ for a given fixture slug.
-}
fixturePrefixBase :: Text
fixturePrefixBase =
    "https://lambdasistemi.github.io/cardano-rdf/fixtures/"

{- | Every @cardano:@-namespaced term the body emitter writes.

Adding a new term requires extending this enum; the serializer's
'vocabIri' / 'vocabCurie' patterns surface gaps via
@-Wincomplete-patterns@. The traceability spec asserts every
@cardano:@-prefixed IRI in the emitter output traces to one of
these.
-}
data VocabTerm
    = -- Classes
      TermTransaction
    | TermInput
    | TermOutput
    | TermAddress
    | TermPaymentCredential
    | TermStakeCredential
    | TermMint
    | TermPolicy
    | TermAsset
    | TermWithdrawal
    | TermStakeDelegation
    | TermVoteDelegation
    | TermPool
    | TermDRep
    | TermRegDeposit
    | TermUnRegDeposit
    | TermStakeRegDeleg
    | TermVoteRegDeleg
    | TermStakeVoteRegDeleg
    | TermRegDRep
    | TermUnRegDRep
    | TermUpdateDRep
    | TermPoolRegistration
    | TermPoolRetirement
    | TermPoolParams
    | TermRelay
    | TermSingleHostAddr
    | TermSingleHostName
    | TermMultiHostName
    | TermPoolMetadata
    | TermAuthCommitteeHotKey
    | TermResignCommitteeColdKey
    | TermDRepAlwaysAbstain
    | TermDRepAlwaysNoConfidence
    | TermDatum
    | TermAuxiliaryData
    | TermGovActionId
    | TermProposal
    | TermGovAction
    | TermTreasuryWithdrawals
    | TermParameterChange
    | TermProtocolParamUpdate
    | TermUpdateCommittee
    | TermCommitteeAddition
    | TermNewConstitution
    | TermConstitution
    | TermHardForkInitiation
    | TermProtocolVersion
    | TermPoolVotingThresholds
    | TermDRepVotingThresholds
    | TermExUnits
    | TermExUnitPrices
    | TermAnchor
    | -- Body predicates
      TermHasInput
    | TermHasOutput
    | TermHasFee
    | TermHasCurrentTreasuryValue
    | TermHasDonation
    | TermResolvedTo
    | TermAtAddress
    | TermBech32
    | TermNetwork
    | TermHasPaymentCredential
    | TermHasStakeCredential
    | TermHasIdentifier
    | TermHasMint
    | TermHasPolicy
    | TermHasAsset
    | TermHasWithdrawal
    | TermOnCredential
    | TermWithdrawalAccount
    | TermHasCertificate
    | TermToPool
    | TermToDRep
    | TermDelegatesToPool
    | TermDelegatesToDRep
    | TermHasDRepCredential
    | TermHasPoolParams
    | TermHasOperator
    | TermHasVrfKeyhash
    | TermHasPledge
    | TermHasCost
    | TermHasMargin
    | TermHasRewardAccount
    | TermHasOwner
    | TermHasRelay
    | TermHasPoolMetadata
    | TermHasPort
    | TermHasIPv4
    | TermHasIPv6
    | TermHasDnsName
    | TermHasUrl
    | TermHasPoolOperator
    | TermRetireAtEpoch
    | TermHasCommitteeColdCredential
    | TermHasCommitteeHotCredential
    | TermHasCollateralInput
    | TermHasReferenceInput
    | TermHasProposal
    | TermHasDeposit
    | TermHasReturnAddress
    | TermHasGovAction
    | TermToRewardAccount
    | TermHasLovelace
    | TermHasGuardPolicy
    | TermHasPriorAction
    | TermHasProtocolParamUpdate
    | TermHasMinFeeA
    | TermHasMinFeeB
    | TermHasMaxBlockBodySize
    | TermHasMaxTxSize
    | TermHasMaxBlockHeaderSize
    | TermHasKeyDeposit
    | TermHasPoolDeposit
    | TermHasMaxEpoch
    | TermHasNOpt
    | TermHasPoolPledgeInfluence
    | TermHasExpansionRate
    | TermHasTreasuryGrowthRate
    | TermHasMinPoolCost
    | TermHasAdaPerUtxoByte
    | TermHasCostModels
    | TermHasExecutionCosts
    | TermHasMaxTxExUnits
    | TermHasMaxBlockExUnits
    | TermHasMaxValueSize
    | TermHasCollateralPercentage
    | TermHasMaxCollateralInputs
    | TermHasPoolVotingThresholds
    | TermHasDRepVotingThresholds
    | TermHasCommitteeMinSize
    | TermHasCommitteeMaxTermLength
    | TermHasGovActionLifetime
    | TermHasGovActionDeposit
    | TermHasDRepDeposit
    | TermHasDRepActivity
    | TermHasMinFeeRefScriptCoinsPerByte
    | TermHasSteps
    | TermHasMemory
    | TermHasPriceMemory
    | TermHasPriceSteps
    | TermHasMotionNoConfidence
    | TermHasCommitteeNormal
    | TermHasCommitteeNoConfidence
    | TermHasUpdateToConstitution
    | TermHasHardForkInitiation
    | TermHasPPSecurityGroup
    | TermHasPPNetworkGroup
    | TermHasPPEconomicGroup
    | TermHasPPTechnicalGroup
    | TermHasPPGovGroup
    | TermHasTreasuryWithdrawal
    | TermHasNewQuorum
    | TermRemovesMember
    | TermAddsMember
    | TermTermLimit
    | TermHasConstitution
    | TermHasGuardrailScript
    | TermHasProtocolVersion
    | TermHasMajorVersion
    | TermHasMinorVersion
    | TermDecodedAs
    | TermFromTxOutRef
    | TermTxOutRef
    | -- Value semantics (T104 / S3 — output ADA + multi-asset)
      TermLovelace
    | TermHasAssetValue
    | TermMintsAsset
    | TermQuantity
    | -- Datum + reference-script sub-block (T105 / S4)
      TermHasDatum
    | TermHasReferenceScript
    | TermHasHash
    | TermHasRawBytes
    | TermIsValid
    | TermHasAuxiliaryData
    | -- Body-root predicates (T107 / S6 — validity interval,
      -- network id, script-data hash, aux-data hash)
      TermHasValidityInterval
    | TermIntervalStart
    | TermIntervalEnd
    | TermNetworkId
    | TermScriptDataHash
    | TermAuxiliaryDataHash
    | -- Required signers (T116 / S15)
      TermHasRequiredSigner
    | -- Collateral (T117 / S16)
      TermTotalCollateral
    | TermHasCollateralReturn
    | -- Reference-script script-language discrimination
      -- (T118 / S17). 'TermPlutusScript' / 'TermNativeScript'
      -- are NOT yet declared canonically; they're invented
      -- locally per A-006 and get exported upstream via T122b.
      TermPlutusScript
    | TermNativeScript
    | TermScriptPubkey
    | TermScriptAll
    | TermScriptAny
    | TermScriptNofK
    | TermInvalidBefore
    | TermInvalidHereafter
    | TermHasVersion
    | TermHasChild
    | TermRequiresSigner
    | TermRequiredCount
    | TermHasSlot
    | -- Voting procedures (T119 / S18). All terms invented
      -- locally per A-006; exported upstream via T122b.
      TermVote
    | TermHasVote
    | TermHasVoter
    | TermHasVotingAction
    | TermHasVerdict
    | TermVoterDRep
    | TermVoterStakePool
    | TermVoterCommitteeCold
    | TermHasAnchor
    | TermAnchorUrl
    | TermAnchorHash
    | -- Raw-bytes identifier literal triples (T119b / S18b).
      -- All three are already canonically declared (pin@a9b5d96
      -- + Phase A predicates) and shipped by the entity-overlay
      -- path; this slice brings the body walker into parity so
      -- the @_:cred_paymentkey_\<hex\>@ raw-bytes bnodes carry
      -- the same @a cardano:Identifier ; cardano:leafType ; cardano:bytesHex@
      -- shape entity-overlay bnodes already carry.
      TermIdentifier
    | TermLeafType
    | TermBytesHex
    | -- Exhaustive cert / proposal cover (T120 / S19, T121 / S20)
      -- — parent class + OpaqueLeaf fallback for variants whose
      -- semantic shape has not been modeled yet. Invented
      -- locally per A-006; exported upstream via T122b.
      TermCertificate
    | TermOpaqueLeaf
    | -- TxOutRef decomposition (T122c / S22). 'fromTxOutRef'
      -- shifts from a flat @"<txid>#<ix>"@ literal to a
      -- typed @cardano:TxOutRef@ node carrying a TxId
      -- Identifier sub-node + a numeric @cardano:hasIndex@,
      -- so SPARQL views can join across positions referencing
      -- the same TxId without literal-string surgery
      -- (operator A-007).
      TermTxOutRefClass
    | TermHasTxId
    | TermHasIndex
    | -- Witness-set seaboard (T128b / S31). PlutusData interpretation
      -- is deferred to #50 — redeemers and datum witnesses carry
      -- opaque CBOR rawBytes until then. All terms below are
      -- invented locally per A-006 and tracked under
      -- @pendingPhaseA3@ in 'VocabTraceabilitySpec' until kmaps#57
      -- lands the Phase A.3 declarations and T128g refreshes the
      -- canonical pin.
      TermRedeemer
    | TermKeyWitness
    | TermBootstrapWitness
    | TermHasRedeemer
    | TermHasKeyWitness
    | TermHasDatumWitness
    | TermHasScriptWitness
    | TermHasBootstrapWitness
    | TermHasPurpose
    | TermHasData
    | TermHasExUnits
    | TermMemoryUnits
    | TermCpuUnits
    | TermHasSignature
    | TermHasVerificationKey
    | -- Transaction-metadata decoding (spec 062). The
      -- auxiliary-data metadata map (@Map Word64 Metadatum@)
      -- decodes into a faithful generic value tree: one
      -- @MetadatumEntry@ per top-level label, each value a
      -- typed node of one of the five Cardano metadatum kinds
      -- (@MetaInt@ / @MetaBytes@ / @MetaText@ / @MetaList@ /
      -- @MetaMap@). Lists keep arity (no chunk joining — that
      -- is spec 063); map keys are full value nodes, not
      -- assumed strings. @bytesHex@ ('TermBytesHex') is reused
      -- for the byte-string leaf.
      TermMetadatumValue
    | TermMetaInt
    | TermMetaBytes
    | TermMetaText
    | TermMetaList
    | TermMetaMap
    | TermMetadatumEntry
    | TermMetadatumElement
    | TermMetadatumMapEntry
    | TermHasMetadatum
    | TermMetadataLabel
    | TermMetadatumValueProp
    | TermIntValue
    | TermTextValue
    | TermHasElement
    | TermElementIndex
    | TermHasEntry
    | TermEntryIndex
    | TermMetaKey
    | TermMetaValue
    deriving stock (Eq, Ord, Show, Enum, Bounded)

{- | The full IRI for a vocab term — e.g.
@"https://…/cardano#hasInput"@. The serializer normally writes
the prefixed CURIE ('vocabCurie'); the IRI form is the canonical
target the traceability spec compares against.
-}
vocabIri :: VocabTerm -> Text
vocabIri = \case
    TermTransaction -> cardanoPrefix <> "Transaction"
    TermInput -> cardanoPrefix <> "Input"
    TermOutput -> cardanoPrefix <> "Output"
    TermAddress -> cardanoPrefix <> "Address"
    TermPaymentCredential -> cardanoPrefix <> "PaymentCredential"
    TermStakeCredential -> cardanoPrefix <> "StakeCredential"
    TermMint -> cardanoPrefix <> "Mint"
    TermPolicy -> cardanoPrefix <> "Policy"
    TermAsset -> cardanoPrefix <> "Asset"
    TermWithdrawal -> cardanoPrefix <> "Withdrawal"
    TermStakeDelegation -> cardanoPrefix <> "StakeDelegation"
    TermVoteDelegation -> cardanoPrefix <> "VoteDelegation"
    TermPool -> cardanoPrefix <> "Pool"
    TermDRep -> cardanoPrefix <> "DRep"
    TermRegDeposit -> cardanoPrefix <> "RegDeposit"
    TermUnRegDeposit -> cardanoPrefix <> "UnRegDeposit"
    TermStakeRegDeleg -> cardanoPrefix <> "StakeRegDeleg"
    TermVoteRegDeleg -> cardanoPrefix <> "VoteRegDeleg"
    TermStakeVoteRegDeleg -> cardanoPrefix <> "StakeVoteRegDeleg"
    TermRegDRep -> cardanoPrefix <> "RegDRep"
    TermUnRegDRep -> cardanoPrefix <> "UnRegDRep"
    TermUpdateDRep -> cardanoPrefix <> "UpdateDRep"
    TermPoolRegistration -> cardanoPrefix <> "PoolRegistration"
    TermPoolRetirement -> cardanoPrefix <> "PoolRetirement"
    TermPoolParams -> cardanoPrefix <> "PoolParams"
    TermRelay -> cardanoPrefix <> "Relay"
    TermSingleHostAddr -> cardanoPrefix <> "SingleHostAddr"
    TermSingleHostName -> cardanoPrefix <> "SingleHostName"
    TermMultiHostName -> cardanoPrefix <> "MultiHostName"
    TermPoolMetadata -> cardanoPrefix <> "PoolMetadata"
    TermAuthCommitteeHotKey -> cardanoPrefix <> "AuthCommitteeHotKey"
    TermResignCommitteeColdKey -> cardanoPrefix <> "ResignCommitteeColdKey"
    TermDRepAlwaysAbstain -> cardanoPrefix <> "DRepAlwaysAbstain"
    TermDRepAlwaysNoConfidence -> cardanoPrefix <> "DRepAlwaysNoConfidence"
    TermDatum -> cardanoPrefix <> "Datum"
    TermAuxiliaryData -> cardanoPrefix <> "AuxiliaryData"
    TermGovActionId -> cardanoPrefix <> "GovActionId"
    TermProposal -> cardanoPrefix <> "Proposal"
    TermGovAction -> cardanoPrefix <> "GovAction"
    TermTreasuryWithdrawals -> cardanoPrefix <> "TreasuryWithdrawals"
    TermParameterChange -> cardanoPrefix <> "ParameterChange"
    TermProtocolParamUpdate -> cardanoPrefix <> "ProtocolParamUpdate"
    TermUpdateCommittee -> cardanoPrefix <> "UpdateCommittee"
    TermCommitteeAddition -> cardanoPrefix <> "CommitteeAddition"
    TermNewConstitution -> cardanoPrefix <> "NewConstitution"
    TermConstitution -> cardanoPrefix <> "Constitution"
    TermHardForkInitiation -> cardanoPrefix <> "HardForkInitiation"
    TermProtocolVersion -> cardanoPrefix <> "ProtocolVersion"
    TermPoolVotingThresholds -> cardanoPrefix <> "PoolVotingThresholds"
    TermDRepVotingThresholds -> cardanoPrefix <> "DRepVotingThresholds"
    TermExUnits -> cardanoPrefix <> "ExUnits"
    TermExUnitPrices -> cardanoPrefix <> "ExUnitPrices"
    TermAnchor -> cardanoPrefix <> "Anchor"
    TermHasInput -> cardanoPrefix <> "hasInput"
    TermHasOutput -> cardanoPrefix <> "hasOutput"
    TermHasFee -> cardanoPrefix <> "hasFee"
    TermHasCurrentTreasuryValue -> cardanoPrefix <> "hasCurrentTreasuryValue"
    TermHasDonation -> cardanoPrefix <> "hasDonation"
    TermResolvedTo -> cardanoPrefix <> "resolvedTo"
    TermAtAddress -> cardanoPrefix <> "atAddress"
    TermBech32 -> cardanoPrefix <> "bech32"
    TermNetwork -> cardanoPrefix <> "network"
    TermHasPaymentCredential -> cardanoPrefix <> "hasPaymentCredential"
    TermHasStakeCredential -> cardanoPrefix <> "hasStakeCredential"
    TermHasIdentifier -> cardanoPrefix <> "hasIdentifier"
    TermHasMint -> cardanoPrefix <> "hasMint"
    TermHasPolicy -> cardanoPrefix <> "hasPolicy"
    TermHasAsset -> cardanoPrefix <> "hasAsset"
    TermHasWithdrawal -> cardanoPrefix <> "hasWithdrawal"
    TermOnCredential -> cardanoPrefix <> "onCredential"
    TermWithdrawalAccount -> cardanoPrefix <> "withdrawalAccount"
    TermHasCertificate -> cardanoPrefix <> "hasCertificate"
    TermToPool -> cardanoPrefix <> "toPool"
    TermToDRep -> cardanoPrefix <> "toDRep"
    TermDelegatesToPool -> cardanoPrefix <> "delegatesToPool"
    TermDelegatesToDRep -> cardanoPrefix <> "delegatesToDRep"
    TermHasDRepCredential -> cardanoPrefix <> "hasDRepCredential"
    TermHasPoolParams -> cardanoPrefix <> "hasPoolParams"
    TermHasOperator -> cardanoPrefix <> "hasOperator"
    TermHasVrfKeyhash -> cardanoPrefix <> "hasVrfKeyhash"
    TermHasPledge -> cardanoPrefix <> "hasPledge"
    TermHasCost -> cardanoPrefix <> "hasCost"
    TermHasMargin -> cardanoPrefix <> "hasMargin"
    TermHasRewardAccount -> cardanoPrefix <> "hasRewardAccount"
    TermHasOwner -> cardanoPrefix <> "hasOwner"
    TermHasRelay -> cardanoPrefix <> "hasRelay"
    TermHasPoolMetadata -> cardanoPrefix <> "hasPoolMetadata"
    TermHasPort -> cardanoPrefix <> "hasPort"
    TermHasIPv4 -> cardanoPrefix <> "hasIPv4"
    TermHasIPv6 -> cardanoPrefix <> "hasIPv6"
    TermHasDnsName -> cardanoPrefix <> "hasDnsName"
    TermHasUrl -> cardanoPrefix <> "hasUrl"
    TermHasPoolOperator -> cardanoPrefix <> "hasPoolOperator"
    TermRetireAtEpoch -> cardanoPrefix <> "retireAtEpoch"
    TermHasCommitteeColdCredential -> cardanoPrefix <> "hasCommitteeColdCredential"
    TermHasCommitteeHotCredential -> cardanoPrefix <> "hasCommitteeHotCredential"
    TermHasCollateralInput -> cardanoPrefix <> "hasCollateralInput"
    TermHasReferenceInput -> cardanoPrefix <> "hasReferenceInput"
    TermHasProposal -> cardanoPrefix <> "hasProposal"
    TermHasDeposit -> cardanoPrefix <> "hasDeposit"
    TermHasReturnAddress -> cardanoPrefix <> "hasReturnAddress"
    TermHasGovAction -> cardanoPrefix <> "hasGovAction"
    TermToRewardAccount -> cardanoPrefix <> "toRewardAccount"
    TermHasLovelace -> cardanoPrefix <> "hasLovelace"
    TermHasGuardPolicy -> cardanoPrefix <> "hasGuardPolicy"
    TermHasPriorAction -> cardanoPrefix <> "hasPriorAction"
    TermHasProtocolParamUpdate -> cardanoPrefix <> "hasProtocolParamUpdate"
    TermHasMinFeeA -> cardanoPrefix <> "hasMinFeeA"
    TermHasMinFeeB -> cardanoPrefix <> "hasMinFeeB"
    TermHasMaxBlockBodySize -> cardanoPrefix <> "hasMaxBlockBodySize"
    TermHasMaxTxSize -> cardanoPrefix <> "hasMaxTxSize"
    TermHasMaxBlockHeaderSize -> cardanoPrefix <> "hasMaxBlockHeaderSize"
    TermHasKeyDeposit -> cardanoPrefix <> "hasKeyDeposit"
    TermHasPoolDeposit -> cardanoPrefix <> "hasPoolDeposit"
    TermHasMaxEpoch -> cardanoPrefix <> "hasMaxEpoch"
    TermHasNOpt -> cardanoPrefix <> "hasNOpt"
    TermHasPoolPledgeInfluence -> cardanoPrefix <> "hasPoolPledgeInfluence"
    TermHasExpansionRate -> cardanoPrefix <> "hasExpansionRate"
    TermHasTreasuryGrowthRate -> cardanoPrefix <> "hasTreasuryGrowthRate"
    TermHasMinPoolCost -> cardanoPrefix <> "hasMinPoolCost"
    TermHasAdaPerUtxoByte -> cardanoPrefix <> "hasAdaPerUtxoByte"
    TermHasCostModels -> cardanoPrefix <> "hasCostModels"
    TermHasExecutionCosts -> cardanoPrefix <> "hasExecutionCosts"
    TermHasMaxTxExUnits -> cardanoPrefix <> "hasMaxTxExUnits"
    TermHasMaxBlockExUnits -> cardanoPrefix <> "hasMaxBlockExUnits"
    TermHasMaxValueSize -> cardanoPrefix <> "hasMaxValueSize"
    TermHasCollateralPercentage -> cardanoPrefix <> "hasCollateralPercentage"
    TermHasMaxCollateralInputs -> cardanoPrefix <> "hasMaxCollateralInputs"
    TermHasPoolVotingThresholds -> cardanoPrefix <> "hasPoolVotingThresholds"
    TermHasDRepVotingThresholds -> cardanoPrefix <> "hasDRepVotingThresholds"
    TermHasCommitteeMinSize -> cardanoPrefix <> "hasCommitteeMinSize"
    TermHasCommitteeMaxTermLength -> cardanoPrefix <> "hasCommitteeMaxTermLength"
    TermHasGovActionLifetime -> cardanoPrefix <> "hasGovActionLifetime"
    TermHasGovActionDeposit -> cardanoPrefix <> "hasGovActionDeposit"
    TermHasDRepDeposit -> cardanoPrefix <> "hasDRepDeposit"
    TermHasDRepActivity -> cardanoPrefix <> "hasDRepActivity"
    TermHasMinFeeRefScriptCoinsPerByte -> cardanoPrefix <> "hasMinFeeRefScriptCoinsPerByte"
    TermHasSteps -> cardanoPrefix <> "hasSteps"
    TermHasMemory -> cardanoPrefix <> "hasMemory"
    TermHasPriceMemory -> cardanoPrefix <> "hasPriceMemory"
    TermHasPriceSteps -> cardanoPrefix <> "hasPriceSteps"
    TermHasMotionNoConfidence -> cardanoPrefix <> "hasMotionNoConfidence"
    TermHasCommitteeNormal -> cardanoPrefix <> "hasCommitteeNormal"
    TermHasCommitteeNoConfidence -> cardanoPrefix <> "hasCommitteeNoConfidence"
    TermHasUpdateToConstitution -> cardanoPrefix <> "hasUpdateToConstitution"
    TermHasHardForkInitiation -> cardanoPrefix <> "hasHardForkInitiation"
    TermHasPPSecurityGroup -> cardanoPrefix <> "hasPPSecurityGroup"
    TermHasPPNetworkGroup -> cardanoPrefix <> "hasPPNetworkGroup"
    TermHasPPEconomicGroup -> cardanoPrefix <> "hasPPEconomicGroup"
    TermHasPPTechnicalGroup -> cardanoPrefix <> "hasPPTechnicalGroup"
    TermHasPPGovGroup -> cardanoPrefix <> "hasPPGovGroup"
    TermHasTreasuryWithdrawal -> cardanoPrefix <> "hasTreasuryWithdrawal"
    TermHasNewQuorum -> cardanoPrefix <> "hasNewQuorum"
    TermRemovesMember -> cardanoPrefix <> "removesMember"
    TermAddsMember -> cardanoPrefix <> "addsMember"
    TermTermLimit -> cardanoPrefix <> "termLimit"
    TermHasConstitution -> cardanoPrefix <> "hasConstitution"
    TermHasGuardrailScript -> cardanoPrefix <> "hasGuardrailScript"
    TermHasProtocolVersion -> cardanoPrefix <> "hasProtocolVersion"
    TermHasMajorVersion -> cardanoPrefix <> "hasMajorVersion"
    TermHasMinorVersion -> cardanoPrefix <> "hasMinorVersion"
    TermDecodedAs -> cardanoPrefix <> "decodedAs"
    TermFromTxOutRef -> cardanoPrefix <> "fromTxOutRef"
    TermTxOutRef -> cardanoPrefix <> "txOutRef"
    TermLovelace -> cardanoPrefix <> "lovelace"
    TermHasAssetValue -> cardanoPrefix <> "hasAssetValue"
    TermMintsAsset -> cardanoPrefix <> "mintsAsset"
    TermQuantity -> cardanoPrefix <> "quantity"
    TermHasDatum -> cardanoPrefix <> "hasDatum"
    TermHasReferenceScript -> cardanoPrefix <> "hasReferenceScript"
    TermHasHash -> cardanoPrefix <> "hasHash"
    TermHasRawBytes -> cardanoPrefix <> "hasRawBytes"
    TermIsValid -> cardanoPrefix <> "isValid"
    TermHasAuxiliaryData -> cardanoPrefix <> "hasAuxiliaryData"
    TermHasValidityInterval -> cardanoPrefix <> "hasValidityInterval"
    TermIntervalStart -> cardanoPrefix <> "intervalStart"
    TermIntervalEnd -> cardanoPrefix <> "intervalEnd"
    TermNetworkId -> cardanoPrefix <> "networkId"
    TermScriptDataHash -> cardanoPrefix <> "scriptDataHash"
    TermAuxiliaryDataHash -> cardanoPrefix <> "auxiliaryDataHash"
    TermHasRequiredSigner -> cardanoPrefix <> "hasRequiredSigner"
    TermTotalCollateral -> cardanoPrefix <> "totalCollateral"
    TermHasCollateralReturn -> cardanoPrefix <> "hasCollateralReturn"
    TermPlutusScript -> cardanoPrefix <> "PlutusScript"
    TermNativeScript -> cardanoPrefix <> "NativeScript"
    TermScriptPubkey -> cardanoPrefix <> "ScriptPubkey"
    TermScriptAll -> cardanoPrefix <> "ScriptAll"
    TermScriptAny -> cardanoPrefix <> "ScriptAny"
    TermScriptNofK -> cardanoPrefix <> "ScriptNofK"
    TermInvalidBefore -> cardanoPrefix <> "InvalidBefore"
    TermInvalidHereafter -> cardanoPrefix <> "InvalidHereafter"
    TermHasVersion -> cardanoPrefix <> "hasVersion"
    TermHasChild -> cardanoPrefix <> "hasChild"
    TermRequiresSigner -> cardanoPrefix <> "requiresSigner"
    TermRequiredCount -> cardanoPrefix <> "requiredCount"
    TermHasSlot -> cardanoPrefix <> "hasSlot"
    TermVote -> cardanoPrefix <> "Vote"
    TermHasVote -> cardanoPrefix <> "hasVote"
    TermHasVoter -> cardanoPrefix <> "hasVoter"
    TermHasVotingAction -> cardanoPrefix <> "hasVotingAction"
    TermHasVerdict -> cardanoPrefix <> "hasVerdict"
    TermVoterDRep -> cardanoPrefix <> "VoterDRep"
    TermVoterStakePool -> cardanoPrefix <> "VoterStakePool"
    TermVoterCommitteeCold -> cardanoPrefix <> "VoterCommitteeCold"
    TermHasAnchor -> cardanoPrefix <> "hasAnchor"
    TermAnchorUrl -> cardanoPrefix <> "anchorUrl"
    TermAnchorHash -> cardanoPrefix <> "anchorHash"
    TermIdentifier -> cardanoPrefix <> "Identifier"
    TermLeafType -> cardanoPrefix <> "leafType"
    TermBytesHex -> cardanoPrefix <> "bytesHex"
    TermCertificate -> cardanoPrefix <> "Certificate"
    TermOpaqueLeaf -> cardanoPrefix <> "OpaqueLeaf"
    TermTxOutRefClass -> cardanoPrefix <> "TxOutRef"
    TermHasTxId -> cardanoPrefix <> "hasTxId"
    TermHasIndex -> cardanoPrefix <> "hasIndex"
    TermRedeemer -> cardanoPrefix <> "Redeemer"
    TermKeyWitness -> cardanoPrefix <> "KeyWitness"
    TermBootstrapWitness -> cardanoPrefix <> "BootstrapWitness"
    TermHasRedeemer -> cardanoPrefix <> "hasRedeemer"
    TermHasKeyWitness -> cardanoPrefix <> "hasKeyWitness"
    TermHasDatumWitness -> cardanoPrefix <> "hasDatumWitness"
    TermHasScriptWitness -> cardanoPrefix <> "hasScriptWitness"
    TermHasBootstrapWitness -> cardanoPrefix <> "hasBootstrapWitness"
    TermHasPurpose -> cardanoPrefix <> "hasPurpose"
    TermHasData -> cardanoPrefix <> "hasData"
    TermHasExUnits -> cardanoPrefix <> "hasExUnits"
    TermMemoryUnits -> cardanoPrefix <> "memoryUnits"
    TermCpuUnits -> cardanoPrefix <> "cpuUnits"
    TermHasSignature -> cardanoPrefix <> "hasSignature"
    TermHasVerificationKey -> cardanoPrefix <> "hasVerificationKey"
    TermMetadatumValue -> cardanoPrefix <> "MetadatumValue"
    TermMetaInt -> cardanoPrefix <> "MetaInt"
    TermMetaBytes -> cardanoPrefix <> "MetaBytes"
    TermMetaText -> cardanoPrefix <> "MetaText"
    TermMetaList -> cardanoPrefix <> "MetaList"
    TermMetaMap -> cardanoPrefix <> "MetaMap"
    TermMetadatumEntry -> cardanoPrefix <> "MetadatumEntry"
    TermMetadatumElement -> cardanoPrefix <> "MetadatumElement"
    TermMetadatumMapEntry -> cardanoPrefix <> "MetadatumMapEntry"
    TermHasMetadatum -> cardanoPrefix <> "hasMetadatum"
    TermMetadataLabel -> cardanoPrefix <> "metadataLabel"
    TermMetadatumValueProp -> cardanoPrefix <> "metadatumValue"
    TermIntValue -> cardanoPrefix <> "intValue"
    TermTextValue -> cardanoPrefix <> "textValue"
    TermHasElement -> cardanoPrefix <> "hasElement"
    TermElementIndex -> cardanoPrefix <> "elementIndex"
    TermHasEntry -> cardanoPrefix <> "hasEntry"
    TermEntryIndex -> cardanoPrefix <> "entryIndex"
    TermMetaKey -> cardanoPrefix <> "metaKey"
    TermMetaValue -> cardanoPrefix <> "metaValue"

{- | The prefixed CURIE form, e.g. @"cardano:hasInput"@. Every
term in this registry lives under the @cardano:@ prefix; the
serializer emits the CURIE form so its output stays byte-equal
to the artisan reference.
-}
vocabCurie :: VocabTerm -> Text
vocabCurie = \case
    TermTransaction -> "cardano:Transaction"
    TermInput -> "cardano:Input"
    TermOutput -> "cardano:Output"
    TermAddress -> "cardano:Address"
    TermPaymentCredential -> "cardano:PaymentCredential"
    TermStakeCredential -> "cardano:StakeCredential"
    TermMint -> "cardano:Mint"
    TermPolicy -> "cardano:Policy"
    TermAsset -> "cardano:Asset"
    TermWithdrawal -> "cardano:Withdrawal"
    TermStakeDelegation -> "cardano:StakeDelegation"
    TermVoteDelegation -> "cardano:VoteDelegation"
    TermPool -> "cardano:Pool"
    TermDRep -> "cardano:DRep"
    TermRegDeposit -> "cardano:RegDeposit"
    TermUnRegDeposit -> "cardano:UnRegDeposit"
    TermStakeRegDeleg -> "cardano:StakeRegDeleg"
    TermVoteRegDeleg -> "cardano:VoteRegDeleg"
    TermStakeVoteRegDeleg -> "cardano:StakeVoteRegDeleg"
    TermRegDRep -> "cardano:RegDRep"
    TermUnRegDRep -> "cardano:UnRegDRep"
    TermUpdateDRep -> "cardano:UpdateDRep"
    TermPoolRegistration -> "cardano:PoolRegistration"
    TermPoolRetirement -> "cardano:PoolRetirement"
    TermPoolParams -> "cardano:PoolParams"
    TermRelay -> "cardano:Relay"
    TermSingleHostAddr -> "cardano:SingleHostAddr"
    TermSingleHostName -> "cardano:SingleHostName"
    TermMultiHostName -> "cardano:MultiHostName"
    TermPoolMetadata -> "cardano:PoolMetadata"
    TermAuthCommitteeHotKey -> "cardano:AuthCommitteeHotKey"
    TermResignCommitteeColdKey -> "cardano:ResignCommitteeColdKey"
    TermDRepAlwaysAbstain -> "cardano:DRepAlwaysAbstain"
    TermDRepAlwaysNoConfidence -> "cardano:DRepAlwaysNoConfidence"
    TermDatum -> "cardano:Datum"
    TermAuxiliaryData -> "cardano:AuxiliaryData"
    TermGovActionId -> "cardano:GovActionId"
    TermProposal -> "cardano:Proposal"
    TermGovAction -> "cardano:GovAction"
    TermTreasuryWithdrawals -> "cardano:TreasuryWithdrawals"
    TermParameterChange -> "cardano:ParameterChange"
    TermProtocolParamUpdate -> "cardano:ProtocolParamUpdate"
    TermUpdateCommittee -> "cardano:UpdateCommittee"
    TermCommitteeAddition -> "cardano:CommitteeAddition"
    TermNewConstitution -> "cardano:NewConstitution"
    TermConstitution -> "cardano:Constitution"
    TermHardForkInitiation -> "cardano:HardForkInitiation"
    TermProtocolVersion -> "cardano:ProtocolVersion"
    TermPoolVotingThresholds -> "cardano:PoolVotingThresholds"
    TermDRepVotingThresholds -> "cardano:DRepVotingThresholds"
    TermExUnits -> "cardano:ExUnits"
    TermExUnitPrices -> "cardano:ExUnitPrices"
    TermAnchor -> "cardano:Anchor"
    TermHasInput -> "cardano:hasInput"
    TermHasOutput -> "cardano:hasOutput"
    TermHasFee -> "cardano:hasFee"
    TermHasCurrentTreasuryValue -> "cardano:hasCurrentTreasuryValue"
    TermHasDonation -> "cardano:hasDonation"
    TermResolvedTo -> "cardano:resolvedTo"
    TermAtAddress -> "cardano:atAddress"
    TermBech32 -> "cardano:bech32"
    TermNetwork -> "cardano:network"
    TermHasPaymentCredential -> "cardano:hasPaymentCredential"
    TermHasStakeCredential -> "cardano:hasStakeCredential"
    TermHasIdentifier -> "cardano:hasIdentifier"
    TermHasMint -> "cardano:hasMint"
    TermHasPolicy -> "cardano:hasPolicy"
    TermHasAsset -> "cardano:hasAsset"
    TermHasWithdrawal -> "cardano:hasWithdrawal"
    TermOnCredential -> "cardano:onCredential"
    TermWithdrawalAccount -> "cardano:withdrawalAccount"
    TermHasCertificate -> "cardano:hasCertificate"
    TermToPool -> "cardano:toPool"
    TermToDRep -> "cardano:toDRep"
    TermDelegatesToPool -> "cardano:delegatesToPool"
    TermDelegatesToDRep -> "cardano:delegatesToDRep"
    TermHasDRepCredential -> "cardano:hasDRepCredential"
    TermHasPoolParams -> "cardano:hasPoolParams"
    TermHasOperator -> "cardano:hasOperator"
    TermHasVrfKeyhash -> "cardano:hasVrfKeyhash"
    TermHasPledge -> "cardano:hasPledge"
    TermHasCost -> "cardano:hasCost"
    TermHasMargin -> "cardano:hasMargin"
    TermHasRewardAccount -> "cardano:hasRewardAccount"
    TermHasOwner -> "cardano:hasOwner"
    TermHasRelay -> "cardano:hasRelay"
    TermHasPoolMetadata -> "cardano:hasPoolMetadata"
    TermHasPort -> "cardano:hasPort"
    TermHasIPv4 -> "cardano:hasIPv4"
    TermHasIPv6 -> "cardano:hasIPv6"
    TermHasDnsName -> "cardano:hasDnsName"
    TermHasUrl -> "cardano:hasUrl"
    TermHasPoolOperator -> "cardano:hasPoolOperator"
    TermRetireAtEpoch -> "cardano:retireAtEpoch"
    TermHasCommitteeColdCredential -> "cardano:hasCommitteeColdCredential"
    TermHasCommitteeHotCredential -> "cardano:hasCommitteeHotCredential"
    TermHasCollateralInput -> "cardano:hasCollateralInput"
    TermHasReferenceInput -> "cardano:hasReferenceInput"
    TermHasProposal -> "cardano:hasProposal"
    TermHasDeposit -> "cardano:hasDeposit"
    TermHasReturnAddress -> "cardano:hasReturnAddress"
    TermHasGovAction -> "cardano:hasGovAction"
    TermToRewardAccount -> "cardano:toRewardAccount"
    TermHasLovelace -> "cardano:hasLovelace"
    TermHasGuardPolicy -> "cardano:hasGuardPolicy"
    TermHasPriorAction -> "cardano:hasPriorAction"
    TermHasProtocolParamUpdate -> "cardano:hasProtocolParamUpdate"
    TermHasMinFeeA -> "cardano:hasMinFeeA"
    TermHasMinFeeB -> "cardano:hasMinFeeB"
    TermHasMaxBlockBodySize -> "cardano:hasMaxBlockBodySize"
    TermHasMaxTxSize -> "cardano:hasMaxTxSize"
    TermHasMaxBlockHeaderSize -> "cardano:hasMaxBlockHeaderSize"
    TermHasKeyDeposit -> "cardano:hasKeyDeposit"
    TermHasPoolDeposit -> "cardano:hasPoolDeposit"
    TermHasMaxEpoch -> "cardano:hasMaxEpoch"
    TermHasNOpt -> "cardano:hasNOpt"
    TermHasPoolPledgeInfluence -> "cardano:hasPoolPledgeInfluence"
    TermHasExpansionRate -> "cardano:hasExpansionRate"
    TermHasTreasuryGrowthRate -> "cardano:hasTreasuryGrowthRate"
    TermHasMinPoolCost -> "cardano:hasMinPoolCost"
    TermHasAdaPerUtxoByte -> "cardano:hasAdaPerUtxoByte"
    TermHasCostModels -> "cardano:hasCostModels"
    TermHasExecutionCosts -> "cardano:hasExecutionCosts"
    TermHasMaxTxExUnits -> "cardano:hasMaxTxExUnits"
    TermHasMaxBlockExUnits -> "cardano:hasMaxBlockExUnits"
    TermHasMaxValueSize -> "cardano:hasMaxValueSize"
    TermHasCollateralPercentage -> "cardano:hasCollateralPercentage"
    TermHasMaxCollateralInputs -> "cardano:hasMaxCollateralInputs"
    TermHasPoolVotingThresholds -> "cardano:hasPoolVotingThresholds"
    TermHasDRepVotingThresholds -> "cardano:hasDRepVotingThresholds"
    TermHasCommitteeMinSize -> "cardano:hasCommitteeMinSize"
    TermHasCommitteeMaxTermLength -> "cardano:hasCommitteeMaxTermLength"
    TermHasGovActionLifetime -> "cardano:hasGovActionLifetime"
    TermHasGovActionDeposit -> "cardano:hasGovActionDeposit"
    TermHasDRepDeposit -> "cardano:hasDRepDeposit"
    TermHasDRepActivity -> "cardano:hasDRepActivity"
    TermHasMinFeeRefScriptCoinsPerByte -> "cardano:hasMinFeeRefScriptCoinsPerByte"
    TermHasSteps -> "cardano:hasSteps"
    TermHasMemory -> "cardano:hasMemory"
    TermHasPriceMemory -> "cardano:hasPriceMemory"
    TermHasPriceSteps -> "cardano:hasPriceSteps"
    TermHasMotionNoConfidence -> "cardano:hasMotionNoConfidence"
    TermHasCommitteeNormal -> "cardano:hasCommitteeNormal"
    TermHasCommitteeNoConfidence -> "cardano:hasCommitteeNoConfidence"
    TermHasUpdateToConstitution -> "cardano:hasUpdateToConstitution"
    TermHasHardForkInitiation -> "cardano:hasHardForkInitiation"
    TermHasPPSecurityGroup -> "cardano:hasPPSecurityGroup"
    TermHasPPNetworkGroup -> "cardano:hasPPNetworkGroup"
    TermHasPPEconomicGroup -> "cardano:hasPPEconomicGroup"
    TermHasPPTechnicalGroup -> "cardano:hasPPTechnicalGroup"
    TermHasPPGovGroup -> "cardano:hasPPGovGroup"
    TermHasTreasuryWithdrawal -> "cardano:hasTreasuryWithdrawal"
    TermHasNewQuorum -> "cardano:hasNewQuorum"
    TermRemovesMember -> "cardano:removesMember"
    TermAddsMember -> "cardano:addsMember"
    TermTermLimit -> "cardano:termLimit"
    TermHasConstitution -> "cardano:hasConstitution"
    TermHasGuardrailScript -> "cardano:hasGuardrailScript"
    TermHasProtocolVersion -> "cardano:hasProtocolVersion"
    TermHasMajorVersion -> "cardano:hasMajorVersion"
    TermHasMinorVersion -> "cardano:hasMinorVersion"
    TermDecodedAs -> "cardano:decodedAs"
    TermFromTxOutRef -> "cardano:fromTxOutRef"
    TermTxOutRef -> "cardano:txOutRef"
    TermLovelace -> "cardano:lovelace"
    TermHasAssetValue -> "cardano:hasAssetValue"
    TermMintsAsset -> "cardano:mintsAsset"
    TermQuantity -> "cardano:quantity"
    TermHasDatum -> "cardano:hasDatum"
    TermHasReferenceScript -> "cardano:hasReferenceScript"
    TermHasHash -> "cardano:hasHash"
    TermHasRawBytes -> "cardano:hasRawBytes"
    TermIsValid -> "cardano:isValid"
    TermHasAuxiliaryData -> "cardano:hasAuxiliaryData"
    TermHasValidityInterval -> "cardano:hasValidityInterval"
    TermIntervalStart -> "cardano:intervalStart"
    TermIntervalEnd -> "cardano:intervalEnd"
    TermNetworkId -> "cardano:networkId"
    TermScriptDataHash -> "cardano:scriptDataHash"
    TermAuxiliaryDataHash -> "cardano:auxiliaryDataHash"
    TermHasRequiredSigner -> "cardano:hasRequiredSigner"
    TermTotalCollateral -> "cardano:totalCollateral"
    TermHasCollateralReturn -> "cardano:hasCollateralReturn"
    TermPlutusScript -> "cardano:PlutusScript"
    TermNativeScript -> "cardano:NativeScript"
    TermScriptPubkey -> "cardano:ScriptPubkey"
    TermScriptAll -> "cardano:ScriptAll"
    TermScriptAny -> "cardano:ScriptAny"
    TermScriptNofK -> "cardano:ScriptNofK"
    TermInvalidBefore -> "cardano:InvalidBefore"
    TermInvalidHereafter -> "cardano:InvalidHereafter"
    TermHasVersion -> "cardano:hasVersion"
    TermHasChild -> "cardano:hasChild"
    TermRequiresSigner -> "cardano:requiresSigner"
    TermRequiredCount -> "cardano:requiredCount"
    TermHasSlot -> "cardano:hasSlot"
    TermVote -> "cardano:Vote"
    TermHasVote -> "cardano:hasVote"
    TermHasVoter -> "cardano:hasVoter"
    TermHasVotingAction -> "cardano:hasVotingAction"
    TermHasVerdict -> "cardano:hasVerdict"
    TermVoterDRep -> "cardano:VoterDRep"
    TermVoterStakePool -> "cardano:VoterStakePool"
    TermVoterCommitteeCold -> "cardano:VoterCommitteeCold"
    TermHasAnchor -> "cardano:hasAnchor"
    TermAnchorUrl -> "cardano:anchorUrl"
    TermAnchorHash -> "cardano:anchorHash"
    TermIdentifier -> "cardano:Identifier"
    TermLeafType -> "cardano:leafType"
    TermBytesHex -> "cardano:bytesHex"
    TermCertificate -> "cardano:Certificate"
    TermOpaqueLeaf -> "cardano:OpaqueLeaf"
    TermTxOutRefClass -> "cardano:TxOutRef"
    TermHasTxId -> "cardano:hasTxId"
    TermHasIndex -> "cardano:hasIndex"
    TermRedeemer -> "cardano:Redeemer"
    TermKeyWitness -> "cardano:KeyWitness"
    TermBootstrapWitness -> "cardano:BootstrapWitness"
    TermHasRedeemer -> "cardano:hasRedeemer"
    TermHasKeyWitness -> "cardano:hasKeyWitness"
    TermHasDatumWitness -> "cardano:hasDatumWitness"
    TermHasScriptWitness -> "cardano:hasScriptWitness"
    TermHasBootstrapWitness -> "cardano:hasBootstrapWitness"
    TermHasPurpose -> "cardano:hasPurpose"
    TermHasData -> "cardano:hasData"
    TermHasExUnits -> "cardano:hasExUnits"
    TermMemoryUnits -> "cardano:memoryUnits"
    TermCpuUnits -> "cardano:cpuUnits"
    TermHasSignature -> "cardano:hasSignature"
    TermHasVerificationKey -> "cardano:hasVerificationKey"
    TermMetadatumValue -> "cardano:MetadatumValue"
    TermMetaInt -> "cardano:MetaInt"
    TermMetaBytes -> "cardano:MetaBytes"
    TermMetaText -> "cardano:MetaText"
    TermMetaList -> "cardano:MetaList"
    TermMetaMap -> "cardano:MetaMap"
    TermMetadatumEntry -> "cardano:MetadatumEntry"
    TermMetadatumElement -> "cardano:MetadatumElement"
    TermMetadatumMapEntry -> "cardano:MetadatumMapEntry"
    TermHasMetadatum -> "cardano:hasMetadatum"
    TermMetadataLabel -> "cardano:metadataLabel"
    TermMetadatumValueProp -> "cardano:metadatumValue"
    TermIntValue -> "cardano:intValue"
    TermTextValue -> "cardano:textValue"
    TermHasElement -> "cardano:hasElement"
    TermElementIndex -> "cardano:elementIndex"
    TermHasEntry -> "cardano:hasEntry"
    TermEntryIndex -> "cardano:entryIndex"
    TermMetaKey -> "cardano:metaKey"
    TermMetaValue -> "cardano:metaValue"

{- | Every vocab term registered in 'VocabTerm', in declaration
order.
-}
allVocabTerms :: [VocabTerm]
allVocabTerms = [minBound .. maxBound]
