{- |
Module      : Cardano.Tx.Graph.Emit.Certificate
Description : Typed RDF walker for Conway certificates.
License     : Apache-2.0

Private emitter helper for Conway certificate variants. It covers
the Conway stake-registration, DRep, pool, and committee
constructors whose CDDL shape carries queryable fields.
-}
module Cardano.Tx.Graph.Emit.Certificate (
    emitTypedCertificateTree,
) where

import Data.ByteString (ByteString)
import Data.ByteString.Short qualified as SBS
import Data.Foldable (toList)
import Data.MemPack.Buffer (byteArrayToShortByteString)
import Data.Ratio (denominator, numerator)
import Data.Set qualified as Set
import Data.Text qualified as Text

import Cardano.Crypto.Hash (hashToBytes)
import Cardano.Ledger.Address (AccountAddress (..), AccountId (..))
import Cardano.Ledger.Api.Tx.Cert (
    Delegatee (DelegStake, DelegStakeVote, DelegVote),
    pattern RegPoolTxCert,
    pattern RetirePoolTxCert,
 )
import Cardano.Ledger.BaseTypes (
    BoundedRational (unboundRational),
    EpochNo (..),
    Port (..),
    StrictMaybe (SJust, SNothing),
    dnsToText,
    urlToText,
 )
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.Governance (Anchor (..))
import Cardano.Ledger.Conway.TxCert (
    pattern AuthCommitteeHotKeyTxCert,
    pattern RegDRepTxCert,
    pattern RegDepositDelegTxCert,
    pattern RegDepositTxCert,
    pattern ResignCommitteeColdTxCert,
    pattern UnRegDRepTxCert,
    pattern UnRegDepositTxCert,
    pattern UpdateDRepTxCert,
 )
import Cardano.Ledger.Core (TxCert)
import Cardano.Ledger.Credential (Credential (KeyHashObj, ScriptHashObj))
import Cardano.Ledger.DRep (
    DRep (
        DRepAlwaysAbstain,
        DRepAlwaysNoConfidence,
        DRepKeyHash,
        DRepScriptHash
    ),
 )
import Cardano.Ledger.Hashes (
    KeyHash (..),
    ScriptHash (..),
    extractHash,
    unVRFVerKeyHash,
 )
import Cardano.Ledger.Keys (
    KeyRole (ColdCommitteeRole, DRepRole, HotCommitteeRole, StakePool, Staking),
 )
import Cardano.Ledger.State (
    PoolMetadata (..),
    StakePoolParams (..),
    StakePoolRelay (..),
 )

import Cardano.Tx.Graph.Emit.Lookup (BnodeName (..), LookupTable)
import Cardano.Tx.Graph.Emit.Monad (Emit, tellTriple)
import Cardano.Tx.Graph.Emit.Triple (
    Object (..),
    Predicate (..),
    Subject (..),
    Triple (..),
 )
import Cardano.Tx.Graph.Emit.Vocab (VocabTerm (..), vocabCurie)
import Cardano.Tx.Graph.Rules.Load.Types (LeafType (..))

type ResolveIdent =
    LookupTable -> LeafType -> ByteString -> Emit Object

{- | Emit a typed certificate tree when the certificate is one of
the Conway variants covered by the typed certificate slice.
-}
emitTypedCertificateTree ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    TxCert ConwayEra ->
    Maybe (Emit ())
emitTypedCertificateTree lookupTbl resolveIdent rootBnode = \case
    RegDepositTxCert cred deposit ->
        Just $
            emitStakeDeposit
                lookupTbl
                resolveIdent
                rootBnode
                TermRegDeposit
                cred
                deposit
    UnRegDepositTxCert cred deposit ->
        Just $
            emitStakeDeposit
                lookupTbl
                resolveIdent
                rootBnode
                TermUnRegDeposit
                cred
                deposit
    RegDepositDelegTxCert cred delegatee deposit ->
        Just $
            emitRegDepositDeleg
                lookupTbl
                resolveIdent
                rootBnode
                cred
                delegatee
                deposit
    RegDRepTxCert cred deposit mAnchor ->
        Just $
            emitDRepCert
                lookupTbl
                resolveIdent
                rootBnode
                TermRegDRep
                cred
                (Just deposit)
                mAnchor
    UnRegDRepTxCert cred deposit ->
        Just $
            emitDRepCert
                lookupTbl
                resolveIdent
                rootBnode
                TermUnRegDRep
                cred
                (Just deposit)
                SNothing
    UpdateDRepTxCert cred mAnchor ->
        Just $
            emitDRepCert
                lookupTbl
                resolveIdent
                rootBnode
                TermUpdateDRep
                cred
                Nothing
                mAnchor
    RegPoolTxCert params ->
        Just $ emitPoolRegistration lookupTbl resolveIdent rootBnode params
    RetirePoolTxCert poolHash epoch ->
        Just $
            emitPoolRetirement lookupTbl resolveIdent rootBnode poolHash epoch
    AuthCommitteeHotKeyTxCert coldCred hotCred ->
        Just $
            emitAuthCommittee
                lookupTbl
                resolveIdent
                rootBnode
                coldCred
                hotCred
    ResignCommitteeColdTxCert coldCred mAnchor ->
        Just $
            emitResignCommittee
                lookupTbl
                resolveIdent
                rootBnode
                coldCred
                mAnchor
    _ -> Nothing

emitStakeDeposit ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    VocabTerm ->
    Credential Staking ->
    Coin ->
    Emit ()
emitStakeDeposit lookupTbl resolveIdent rootBnode classTerm cred deposit = do
    certHeader rootBnode classTerm
    stakeBnode <- resolveStakeCredential lookupTbl resolveIdent cred
    tellObj rootBnode TermHasStakeCredential stakeBnode
    tellCoin rootBnode TermHasDeposit deposit

emitRegDepositDeleg ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    Credential Staking ->
    Delegatee ->
    Coin ->
    Emit ()
emitRegDepositDeleg lookupTbl resolveIdent rootBnode cred delegatee deposit = do
    stakeBnode <- resolveStakeCredential lookupTbl resolveIdent cred
    case delegatee of
        DelegStake poolHash -> do
            certHeader rootBnode TermStakeRegDeleg
            tellObj rootBnode TermHasStakeCredential stakeBnode
            poolBnode <-
                resolveIdent lookupTbl PoolId (keyHashBytes poolHash)
            tellObj rootBnode TermDelegatesToPool poolBnode
            tellCoin rootBnode TermHasDeposit deposit
        DelegVote drep -> do
            certHeader rootBnode TermVoteRegDeleg
            tellObj rootBnode TermHasStakeCredential stakeBnode
            drepBnode <-
                emitDRepTarget lookupTbl resolveIdent rootBnode drep
            tellObj rootBnode TermDelegatesToDRep drepBnode
            tellCoin rootBnode TermHasDeposit deposit
        DelegStakeVote poolHash drep -> do
            certHeader rootBnode TermStakeVoteRegDeleg
            tellObj rootBnode TermHasStakeCredential stakeBnode
            poolBnode <-
                resolveIdent lookupTbl PoolId (keyHashBytes poolHash)
            drepBnode <-
                emitDRepTarget lookupTbl resolveIdent rootBnode drep
            tellObj rootBnode TermDelegatesToPool poolBnode
            tellObj rootBnode TermDelegatesToDRep drepBnode
            tellCoin rootBnode TermHasDeposit deposit

emitDRepCert ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    VocabTerm ->
    Credential DRepRole ->
    Maybe Coin ->
    StrictMaybe Anchor ->
    Emit ()
emitDRepCert
    lookupTbl
    resolveIdent
    rootBnode
    classTerm
    cred
    mDeposit
    mAnchor = do
        certHeader rootBnode classTerm
        drepBnode <-
            resolveCredential
                lookupTbl
                resolveIdent
                DRepKey
                DRepScript
                cred
        tellObj rootBnode TermHasDRepCredential drepBnode
        mapM_ (tellCoin rootBnode TermHasDeposit) mDeposit
        emitMaybeAnchor lookupTbl resolveIdent rootBnode "Anchor" mAnchor

emitPoolRegistration ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    StakePoolParams ->
    Emit ()
emitPoolRegistration
    lookupTbl
    resolveIdent
    rootBnode
    StakePoolParams
        { sppId = operator
        , sppVrf = vrfHash
        , sppPledge = pledge
        , sppCost = cost
        , sppMargin = margin
        , sppAccountAddress = reward
        , sppOwners = owners
        , sppRelays = relays
        , sppMetadata = metadata
        } = do
        let paramsBnode = childBnode rootBnode "PoolParams"
        certHeader rootBnode TermPoolRegistration
        tellObj rootBnode TermHasPoolParams (OBnode paramsBnode)
        tellType paramsBnode TermPoolParams
        operatorBnode <-
            resolveIdent lookupTbl PoolId (keyHashBytes operator)
        vrfBnode <-
            resolveIdent
                lookupTbl
                LtVrfKeyHash
                (hashToBytes (unVRFVerKeyHash vrfHash))
        rewardBnode <- resolveRewardAccount lookupTbl resolveIdent reward
        tellObj paramsBnode TermHasOperator operatorBnode
        tellObj paramsBnode TermHasVrfKeyhash vrfBnode
        tellCoin paramsBnode TermHasPledge pledge
        tellCoin paramsBnode TermHasCost cost
        tellText paramsBnode TermHasMargin (renderRational margin)
        tellObj paramsBnode TermHasRewardAccount rewardBnode
        mapM_
            (emitOwner lookupTbl resolveIdent paramsBnode)
            (Set.toList owners)
        mapM_
            (emitRelay paramsBnode)
            (zip [1 :: Int ..] (toList relays))
        emitPoolMetadata lookupTbl resolveIdent paramsBnode metadata

emitPoolRetirement ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    KeyHash StakePool ->
    EpochNo ->
    Emit ()
emitPoolRetirement lookupTbl resolveIdent rootBnode poolHash (EpochNo epoch) = do
    certHeader rootBnode TermPoolRetirement
    poolBnode <- resolveIdent lookupTbl PoolId (keyHashBytes poolHash)
    tellObj rootBnode TermHasPoolOperator poolBnode
    tellInt rootBnode TermRetireAtEpoch (fromIntegral epoch)

emitAuthCommittee ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    Credential ColdCommitteeRole ->
    Credential HotCommitteeRole ->
    Emit ()
emitAuthCommittee lookupTbl resolveIdent rootBnode coldCred hotCred = do
    certHeader rootBnode TermAuthCommitteeHotKey
    coldBnode <-
        resolveCredential
            lookupTbl
            resolveIdent
            CommitteeColdKey
            CommitteeColdScript
            coldCred
    hotBnode <-
        resolveCredential
            lookupTbl
            resolveIdent
            CommitteeHotKey
            CommitteeHotScript
            hotCred
    tellObj rootBnode TermHasCommitteeColdCredential coldBnode
    tellObj rootBnode TermHasCommitteeHotCredential hotBnode

emitResignCommittee ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    Credential ColdCommitteeRole ->
    StrictMaybe Anchor ->
    Emit ()
emitResignCommittee lookupTbl resolveIdent rootBnode coldCred mAnchor = do
    certHeader rootBnode TermResignCommitteeColdKey
    coldBnode <-
        resolveCredential
            lookupTbl
            resolveIdent
            CommitteeColdKey
            CommitteeColdScript
            coldCred
    tellObj rootBnode TermHasCommitteeColdCredential coldBnode
    emitMaybeAnchor lookupTbl resolveIdent rootBnode "Anchor" mAnchor

emitDRepTarget ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    DRep ->
    Emit Object
emitDRepTarget lookupTbl resolveIdent rootBnode = \case
    DRepKeyHash h -> resolveIdent lookupTbl DRepKey (keyHashBytes h)
    DRepScriptHash h -> resolveIdent lookupTbl DRepScript (scriptHashBytes h)
    DRepAlwaysAbstain -> do
        let drepBnode = childBnode rootBnode "DRepAlwaysAbstain"
        tellType drepBnode TermDRep
        tellType drepBnode TermDRepAlwaysAbstain
        pure (OBnode drepBnode)
    DRepAlwaysNoConfidence -> do
        let drepBnode = childBnode rootBnode "DRepAlwaysNoConfidence"
        tellType drepBnode TermDRep
        tellType drepBnode TermDRepAlwaysNoConfidence
        pure (OBnode drepBnode)

emitOwner ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    KeyHash Staking ->
    Emit ()
emitOwner lookupTbl resolveIdent paramsBnode owner = do
    ownerBnode <- resolveIdent lookupTbl StakeKey (keyHashBytes owner)
    tellObj paramsBnode TermHasOwner ownerBnode

emitRelay :: BnodeName -> (Int, StakePoolRelay) -> Emit ()
emitRelay paramsBnode (relayIx, relay) = do
    let relayBnode = childBnode paramsBnode ("Relay" <> Text.pack (show relayIx))
    tellObj paramsBnode TermHasRelay (OBnode relayBnode)
    tellType relayBnode TermRelay
    case relay of
        SingleHostAddr mPort mIpv4 mIpv6 -> do
            tellType relayBnode TermSingleHostAddr
            emitMaybePort relayBnode mPort
            emitStrictMaybe relayBnode TermHasIPv4 (Text.pack . show) mIpv4
            emitStrictMaybe relayBnode TermHasIPv6 (Text.pack . show) mIpv6
        SingleHostName mPort dnsName -> do
            tellType relayBnode TermSingleHostName
            emitMaybePort relayBnode mPort
            tellText relayBnode TermHasDnsName (dnsToText dnsName)
        MultiHostName dnsName -> do
            tellType relayBnode TermMultiHostName
            tellText relayBnode TermHasDnsName (dnsToText dnsName)

emitPoolMetadata ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    StrictMaybe PoolMetadata ->
    Emit ()
emitPoolMetadata _ _ _ SNothing = pure ()
emitPoolMetadata lookupTbl resolveIdent paramsBnode (SJust (PoolMetadata url hash)) = do
    let metadataBnode = childBnode paramsBnode "Metadata"
        hashBytes = SBS.fromShort (byteArrayToShortByteString hash)
    hashBnode <- resolveIdent lookupTbl LtPoolMetadataHash hashBytes
    tellObj paramsBnode TermHasPoolMetadata (OBnode metadataBnode)
    tellType metadataBnode TermPoolMetadata
    tellText metadataBnode TermHasUrl (urlToText url)
    tellObj metadataBnode TermHasHash hashBnode

emitMaybeAnchor ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    Text.Text ->
    StrictMaybe Anchor ->
    Emit ()
emitMaybeAnchor _ _ _ _ SNothing = pure ()
emitMaybeAnchor lookupTbl resolveIdent rootBnode suffix (SJust anchor) =
    emitAnchor lookupTbl resolveIdent rootBnode (childBnode rootBnode suffix) anchor

emitAnchor ::
    LookupTable ->
    ResolveIdent ->
    BnodeName ->
    BnodeName ->
    Anchor ->
    Emit ()
emitAnchor lookupTbl resolveIdent parentBnode anchorBnode (Anchor url dataHash) = do
    hashBnode <-
        resolveIdent
            lookupTbl
            LtAnchorDataHash
            (hashToBytes (extractHash dataHash))
    tellObj parentBnode TermHasAnchor (OBnode anchorBnode)
    tellType anchorBnode TermAnchor
    tellText anchorBnode TermAnchorUrl (urlToText url)
    tellObj anchorBnode TermAnchorHash hashBnode

resolveStakeCredential ::
    LookupTable ->
    ResolveIdent ->
    Credential Staking ->
    Emit Object
resolveStakeCredential lookupTbl resolveIdent =
    resolveCredential lookupTbl resolveIdent StakeKey StakeScript

resolveRewardAccount ::
    LookupTable ->
    ResolveIdent ->
    AccountAddress ->
    Emit Object
resolveRewardAccount lookupTbl resolveIdent (AccountAddress _ accountId) =
    case accountId of
        AccountId cred -> resolveStakeCredential lookupTbl resolveIdent cred

resolveCredential ::
    LookupTable ->
    ResolveIdent ->
    LeafType ->
    LeafType ->
    Credential kr ->
    Emit Object
resolveCredential lookupTbl resolveIdent keyLeaf scriptLeaf = \case
    KeyHashObj h -> resolveIdent lookupTbl keyLeaf (keyHashBytes h)
    ScriptHashObj h -> resolveIdent lookupTbl scriptLeaf (scriptHashBytes h)

certHeader :: BnodeName -> VocabTerm -> Emit ()
certHeader bnode classTerm = do
    tellType bnode TermCertificate
    tellType bnode classTerm

tellType :: BnodeName -> VocabTerm -> Emit ()
tellType bnode term =
    tellTriple (Triple (SBnode bnode) PRdfType (OIri (vocabCurie term)))

tellObj :: BnodeName -> VocabTerm -> Object -> Emit ()
tellObj subj term obj =
    tellTriple
        ( Triple
            (SBnode subj)
            (PIri (vocabCurie term))
            obj
        )

tellText :: BnodeName -> VocabTerm -> Text.Text -> Emit ()
tellText subj term txt =
    tellTriple
        ( Triple
            (SBnode subj)
            (PIri (vocabCurie term))
            (OStringLit txt)
        )

tellInt :: BnodeName -> VocabTerm -> Integer -> Emit ()
tellInt subj term n =
    tellTriple
        ( Triple
            (SBnode subj)
            (PIri (vocabCurie term))
            (OIntLit n)
        )

tellCoin :: BnodeName -> VocabTerm -> Coin -> Emit ()
tellCoin subj term (Coin n) =
    tellInt subj term (fromIntegral n)

emitMaybePort :: BnodeName -> StrictMaybe Port -> Emit ()
emitMaybePort _ SNothing = pure ()
emitMaybePort bnode (SJust (Port port)) =
    tellInt bnode TermHasPort (fromIntegral port)

emitStrictMaybe ::
    BnodeName ->
    VocabTerm ->
    (a -> Text.Text) ->
    StrictMaybe a ->
    Emit ()
emitStrictMaybe _ _ _ SNothing = pure ()
emitStrictMaybe bnode term render (SJust x) =
    tellText bnode term (render x)

keyHashBytes :: KeyHash r -> ByteString
keyHashBytes (KeyHash h) = hashToBytes h

scriptHashBytes :: ScriptHash -> ByteString
scriptHashBytes (ScriptHash h) = hashToBytes h

renderRational :: (BoundedRational r) => r -> Text.Text
renderRational r =
    let q = unboundRational r
     in Text.pack (show (numerator q) <> "/" <> show (denominator q))

childBnode :: BnodeName -> Text.Text -> BnodeName
childBnode (BnodeName parent) suffix =
    BnodeName (parent <> suffix)
