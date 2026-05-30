#!/usr/bin/env python3
"""One-shot script: ensure every class / predicate in
`vocab/cardano/transactions.ttl` and `vocab/treasury/overlay.ttl`
carries an `rdfs:comment` summarising the on-chain semantics in
at least one sentence (issue #76 acceptance).

Strategy:

* When a term already has a `dcterms:description`, alias its first
  description as `rdfs:comment` so both Dublin Core consumers and
  raw `rdfs:` consumers get the same prose.

* When a term has neither, emit a default one-sentence
  `rdfs:comment` derived from the label and the term's local part.

The script rewrites the source files in-place using textual edits
(`<entry> a <kind> ; rdfs:label "<L>"` → `<entry> a <kind> ;
rdfs:label "<L>" ; rdfs:comment "<comment>"`), preserving the file's
single-line-per-term layout where it exists. It is idempotent: a
second run is a no-op.

Used once as part of the issue #76 documentation pass. Not wired
into CI.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

import rdflib
from rdflib.namespace import RDF, RDFS, OWL

REPO_ROOT = Path(__file__).resolve().parents[1]
DCTERMS_DESCRIPTION = rdflib.URIRef("http://purl.org/dc/terms/description")

# ------------------------------------------------------------------------
# Default comments. Each entry maps a local part to a one-sentence on-chain
# semantics summary. Used only when the term has no dcterms:description.
# Curated to cover the 96 vocab terms that lacked any prose before
# issue #76 slice 3 (see WIP.md).
# ------------------------------------------------------------------------
DEFAULTS: Dict[str, str] = {
    # Conway certificate variants
    "AuthCommitteeHotKey": "Conway certificate authorising a hot key for an existing constitutional committee member.",
    "DRepAlwaysAbstain": "Predefined DRep target that always votes abstain on every governance action.",
    "DRepAlwaysNoConfidence": "Predefined DRep target that always votes no-confidence on every governance action.",
    "MultiHostName": "Stake-pool relay variant naming a multi-host DNS record (round-robin / failover entry).",
    "PoolMetadata": "Off-chain pool metadata anchor: URL plus a hash of the canonical metadata JSON.",
    "PoolParams": "The full Conway-era stake-pool parameter record: operator key, VRF key, pledge, costs, margin, reward account, owners, relays, optional metadata anchor.",
    "PoolRegistration": "Stake-pool registration certificate that binds a new pool's parameters to the chain.",
    "PoolRetirement": "Stake-pool retirement certificate declaring the epoch at which the pool will deregister.",
    "RegDRep": "Conway certificate registering a DRep with a deposit and an optional metadata anchor.",
    "RegDeposit": "Conway certificate registering a stake credential and locking the registration deposit.",
    "Relay": "Stake-pool relay entry: either a single host (IP or DNS) or a multi-host DNS record.",
    "ResignCommitteeColdKey": "Conway certificate resigning a constitutional committee member's cold key.",
    "SingleHostAddr": "Stake-pool relay variant naming a single host by IPv4 / IPv6 address and optional port.",
    "SingleHostName": "Stake-pool relay variant naming a single host by DNS name and optional port.",
    "StakeRegDeleg": "Conway combined certificate that registers a stake credential and delegates it to a pool in one step.",
    "StakeVoteRegDeleg": "Conway combined certificate that registers a stake credential, delegates it to a pool, and binds it to a DRep in one step.",
    "UnRegDRep": "Conway certificate deregistering a DRep and returning its deposit.",
    "UnRegDeposit": "Conway certificate deregistering a stake credential and returning its registration deposit.",
    "UpdateDRep": "Conway certificate updating a registered DRep's metadata anchor without changing its deposit.",
    "VoteRegDeleg": "Conway combined certificate that registers a stake credential and binds it to a DRep in one step.",
    # Protocol parameters (Conway-era pp_*)
    "hasMinFeeA": "Per-byte component of the Conway transaction fee (`a` in `fee = a * size + b`).",
    "hasMinFeeB": "Constant component of the Conway transaction fee (`b` in `fee = a * size + b`).",
    "hasMaxBlockBodySize": "Protocol-parameter bound on the maximum block body size in bytes.",
    "hasMaxTxSize": "Protocol-parameter bound on the maximum transaction size in bytes.",
    "hasMaxBlockHeaderSize": "Protocol-parameter bound on the maximum block header size in bytes.",
    "hasKeyDeposit": "Lovelace deposit a stake credential must lock at registration time.",
    "hasPoolDeposit": "Lovelace deposit a stake pool must lock at registration time.",
    "hasMaxEpoch": "Maximum number of epochs into the future a pool retirement can be scheduled.",
    "hasNOpt": "Desired number of stake pools targeted by the saturation curve (`k` in stake-pool reward math).",
    "hasPoolPledgeInfluence": "Influence factor of pool pledge on rewards (`a0`).",
    "hasExpansionRate": "Per-epoch monetary expansion rate (`rho`).",
    "hasTreasuryGrowthRate": "Per-epoch fraction of expansion sent to the treasury (`tau`).",
    "hasMinPoolCost": "Minimum declared fixed cost a pool may set in its parameters.",
    "hasAdaPerUtxoByte": "Lovelace charged per byte of UTxO storage (Conway-era replacement for `minUTxOValue`).",
    "hasCostModels": "Plutus cost model table (one entry per supported Plutus language version).",
    "hasExecutionCosts": "Per-unit prices for Plutus execution budgets (memory + steps).",
    "hasMaxTxExUnits": "Maximum Plutus execution budget allowed for a single transaction.",
    "hasMaxBlockExUnits": "Maximum aggregate Plutus execution budget allowed for a single block.",
    "hasMaxValueSize": "Protocol-parameter bound on the encoded size of a single Value (lovelace + assets).",
    "hasCollateralPercentage": "Percentage of script fees that must be covered by collateral inputs.",
    "hasMaxCollateralInputs": "Protocol-parameter bound on the number of collateral inputs per transaction.",
    "hasPoolVotingThresholds": "Per-governance-action thresholds the SPO voting bloc must clear.",
    "hasDRepVotingThresholds": "Per-governance-action thresholds the DRep voting bloc must clear.",
    "hasCommitteeMinSize": "Minimum size of the constitutional committee.",
    "hasCommitteeMaxTermLength": "Maximum term length, in epochs, a committee member may serve.",
    "hasGovActionLifetime": "Number of epochs a governance action remains votable before expiring.",
    "hasGovActionDeposit": "Lovelace deposit required to submit a governance action.",
    "hasDRepDeposit": "Lovelace deposit required to register a DRep.",
    "hasDRepActivity": "Number of epochs of inactivity after which a DRep is considered dormant.",
    "hasMinFeeRefScriptCoinsPerByte": "Conway extra fee charged per byte of reference-script payload included via reference inputs.",
    "hasSteps": "Plutus execution-budget steps component.",
    "hasMemory": "Plutus execution-budget memory component.",
    "hasPriceMemory": "Per-unit price of Plutus memory inside `hasExecutionCosts`.",
    "hasPriceSteps": "Per-unit price of Plutus steps inside `hasExecutionCosts`.",
    # Voting threshold breakdown
    "hasMotionNoConfidence": "Voting threshold for a motion of no-confidence governance action.",
    "hasCommitteeNormal": "Voting threshold for a normal committee update governance action.",
    "hasCommitteeNoConfidence": "Voting threshold for a committee update during no-confidence.",
    "hasUpdateToConstitution": "Voting threshold for a constitution update governance action.",
    "hasHardForkInitiation": "Voting threshold for a hard-fork-initiation governance action.",
    "hasPPSecurityGroup": "Voting threshold for protocol-parameter changes in the security parameter group.",
    "hasPPNetworkGroup": "Voting threshold for protocol-parameter changes in the network parameter group.",
    "hasPPEconomicGroup": "Voting threshold for protocol-parameter changes in the economic parameter group.",
    "hasPPTechnicalGroup": "Voting threshold for protocol-parameter changes in the technical parameter group.",
    "hasPPGovGroup": "Voting threshold for protocol-parameter changes in the governance parameter group.",
    # Governance action payload predicates
    "hasTreasuryWithdrawal": "Reward-account withdrawal entry inside a treasury-withdrawals governance action.",
    "hasNewQuorum": "New committee quorum threshold proposed by a committee-update governance action.",
    "removesMember": "Committee member removed by an update-committee governance action.",
    "addsMember": "Committee member added by an update-committee governance action.",
    "termLimit": "Epoch at which a committee member's term expires.",
    "hasConstitution": "Anchor of the constitution document referenced by a new-constitution governance action.",
    "hasGuardrailScript": "Optional guardrail script hash bound to the constitution.",
    "hasProtocolVersion": "Conway protocol-version record (major + minor) bound to a hard-fork-initiation action.",
    "hasMajorVersion": "Major protocol-version number.",
    "hasMinorVersion": "Minor protocol-version number.",
    # Delegation predicates
    "delegatesToDRep": "Delegation edge: a stake credential's voting power is bound to the named DRep.",
    "delegatesToPool": "Delegation edge: a stake credential's block-production stake is bound to the named stake pool.",
    # Committee/DRep credential predicates
    "hasCommitteeColdCredential": "Cold credential of a constitutional committee member.",
    "hasCommitteeHotCredential": "Hot credential of a constitutional committee member, authorised by an `AuthCommitteeHotKey` certificate.",
    "hasCost": "Pool-parameter declared fixed cost the pool charges per epoch before margin.",
    "hasDRepCredential": "Credential identifying a registered DRep.",
    "hasDnsName": "DNS-name field of a pool relay entry.",
    "hasIPv4": "IPv4 address field of a pool relay entry.",
    "hasIPv6": "IPv6 address field of a pool relay entry.",
    "hasMargin": "Pool-parameter operator margin: the fraction of rewards retained by the pool operator.",
    "hasOperator": "Pool key hash of the pool operator's cold key.",
    "hasOwner": "Stake-key hash of one of a pool's registered owners.",
    "hasPledge": "Pool-parameter declared pledge (lovelace the operator commits to the pool).",
    "hasPoolMetadata": "Off-chain metadata anchor of a stake pool (URL + hash).",
    "hasPoolOperator": "Pool key hash identifying the pool an operation targets.",
    "hasPoolParams": "Reference to the pool-parameter record bundled with a `PoolRegistration` certificate.",
    "hasPort": "Optional TCP port of a single-host pool relay entry.",
    "hasRelay": "Pool-parameter relay entry (single-host, multi-host, or DNS).",
    "hasRewardAccount": "Reward account into which a stake pool's epochly rewards are paid.",
    "hasUrl": "URL of an off-chain anchor (metadata, anchor doc).",
    "hasVrfKeyhash": "Pool-parameter VRF key hash used for block production.",
    "retireAtEpoch": "Epoch at which a stake-pool retirement certificate scheduled the pool to retire.",
}


def expected_namespace_map() -> Dict[Path, str]:
    return {
        REPO_ROOT / "vocab" / "cardano" / "transactions.ttl":
            "https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#",
        REPO_ROOT / "vocab" / "treasury" / "overlay.ttl":
            "https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#",
    }


def collect_terms(graph: rdflib.Graph) -> List[rdflib.URIRef]:
    subjects: Set[rdflib.URIRef] = set()
    for cls in (RDFS.Class, RDF.Property):
        for subject in graph.subjects(RDF.type, cls):
            if isinstance(subject, rdflib.URIRef):
                subjects.add(subject)
    return sorted(subjects, key=str)


def existing_comment(graph: rdflib.Graph, term: rdflib.URIRef) -> Optional[str]:
    for obj in graph.objects(term, RDFS.comment):
        return str(obj)
    return None


def existing_description(graph: rdflib.Graph, term: rdflib.URIRef) -> Optional[str]:
    for obj in graph.objects(term, DCTERMS_DESCRIPTION):
        return str(obj)
    return None


def add_comment_text(path: Path, term_local: str, comment: str) -> bool:
    """Add `rdfs:comment "<comment>"` to the first declaration of
    `cardano:<term_local>` / `treasury:<term_local>` in `path`'s
    Turtle source.

    Returns True if a write happened.
    """
    text = path.read_text(encoding="utf-8")

    # Single-line form: `cardano:Foo a rdfs:Class ; rdfs:label "Foo" .`
    single_pattern = re.compile(
        r"^(\s*(?:cardano|treasury):"
        + re.escape(term_local)
        + r"\b[^.\n]*?rdfs:label\s+\"[^\"\n]+\")\s*\.\s*$",
        flags=re.MULTILINE,
    )

    def single_repl(match: re.Match[str]) -> str:
        return (
            f"{match.group(1)} ;\n"
            f"  rdfs:comment \"{comment}\" .\n"
        )

    new_text, n = single_pattern.subn(single_repl, text, count=1)
    if n == 1:
        path.write_text(new_text, encoding="utf-8")
        return True

    # Multi-line form ending in `dcterms:description "..." .`. We
    # convert the trailing `.` after the description into ` ;` and
    # add an `rdfs:comment "..."` line with the same content. This
    # alias path handles entries that already have a description but
    # no rdfs:comment.
    description_pattern = re.compile(
        r"^(\s*(?:cardano|treasury):"
        + re.escape(term_local)
        + r"\b[^.]*?dcterms:description\s+(\"(?:[^\"\\]|\\.)*\"))\s*\.\s*$",
        flags=re.MULTILINE | re.DOTALL,
    )

    def description_repl(match: re.Match[str]) -> str:
        desc_literal = match.group(2)
        return (
            f"{match.group(1)} ;\n"
            f"  rdfs:comment {desc_literal} .\n"
        )

    new_text, n = description_pattern.subn(description_repl, text, count=1)
    if n == 1:
        path.write_text(new_text, encoding="utf-8")
        return True

    return False


def synth_comment(term_local: str, label: Optional[str]) -> str:
    if term_local in DEFAULTS:
        return DEFAULTS[term_local]
    if label is not None:
        return f"Vocabulary term '{label}' used by the Cardano transaction RDF emitter."
    return f"Vocabulary term '{term_local}' used by the Cardano transaction RDF emitter."


def process_file(path: Path, namespace_iri: str) -> Tuple[int, int, List[str]]:
    graph = rdflib.Graph()
    graph.parse(path, format="turtle")
    terms = collect_terms(graph)
    aliased = 0
    synthesised = 0
    missing: List[str] = []
    for term in terms:
        local = str(term)[len(namespace_iri):] if str(term).startswith(namespace_iri) else str(term).rsplit("#", 1)[-1]
        if existing_comment(graph, term) is not None:
            continue
        desc = existing_description(graph, term)
        if desc is not None:
            if add_comment_text(path, local, desc):
                aliased += 1
            else:
                missing.append(f"{local} (alias)")
        else:
            label_value: Optional[str] = None
            for obj in graph.objects(term, RDFS.label):
                label_value = str(obj)
                break
            comment = synth_comment(local, label_value)
            if add_comment_text(path, local, comment):
                synthesised += 1
            else:
                missing.append(f"{local} (synthesise)")
    return aliased, synthesised, missing


def main() -> int:
    overall_failures: List[str] = []
    for path, namespace in expected_namespace_map().items():
        if not path.exists():
            print(f"missing: {path}", file=sys.stderr)
            continue
        aliased, synthesised, failures = process_file(path, namespace)
        print(f"{path.relative_to(REPO_ROOT)}: aliased={aliased} synthesised={synthesised}")
        overall_failures.extend(failures)
    if overall_failures:
        print("could not edit:", file=sys.stderr)
        for entry in overall_failures:
            print(f"  - {entry}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
