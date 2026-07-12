# Feature Specification: Type voting-procedure voters as resolvable Identifier nodes

**Feature Branch**: `feat/98-voting-voter-identifier`  
**Issue**: [lambdasistemi/cardano-ledger-rdf#98](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/98)  
**Status**: In progress

## Problem

The voting-procedure emitter writes the voter credential as an opaque hex
literal. Unlike every other credential-bearing emitter surface, that value is
not a `cardano:Identifier`, so an operator resolution book cannot associate a
vote with a named entity.

## User Story

As a consumer of tx-graph RDF output, I see a voting procedure's voter
credential emitted as a proper `cardano:Identifier` IRI (same shape as
required signers, stake credentials, etc.), so resolution books can answer
"who cast this vote?"

## Functional Requirements

- **FR-001**: `CommitteeVoter`, `DRepVoter`, and `StakePoolVoter` must emit
  their voter credential through `resolveCredentialAndIntroduceIdent`.
- **FR-002**: Committee and DRep credential discrimination must preserve the
  ledger credential form: key hashes use `CommitteeHotKey` / `DRepKey`; script
  hashes use `CommitteeHotScript` / `DRepScript`; pool voters use `PoolId`.
- **FR-003**: The voter node must continue to carry its existing voter-class
  triple and point to the identifier node with `cardano:hasIdentifier`.
- **FR-004**: A registered golden fixture must contain a voting procedure and
  pin the resulting `urn:cardano:id:...` identifier, its
  `cardano:Identifier` type, `cardano:leafType`, and `cardano:bytesHex`.

## Acceptance Criteria (verbatim from issue #98)

- [ ] `emitVoterBlock`/`voterDiscrimination` routes CommitteeVoter/DRepVoter/StakePoolVoter credentials through `resolveCredentialAndIntroduceIdent` with the correct `LeafType` (`CommitteeHotKey`/`CommitteeHotScript`, `DRepKey`/`DRepScript`, `PoolId` as applicable) instead of emitting a plain `OStringLit` hex string
- [ ] Golden fixture with a voting-procedure transaction shows the voter credential as `a cardano:Identifier ; cardano:leafType ... ; cardano:bytesHex ...` at a proper `urn:cardano:id:...` IRI
- [ ] Existing voting-procedure fixtures regenerate cleanly with no unrelated diff
- [ ] `nix develop -c just unit` and the standard flake checks (`build`, `unit`, `lint`, `vocab-validate`, `vocab-owl-smoke`) pass

## Out of Scope

- Resolution-book and query changes in `cardano-ledger-inspector`.
- Other voting-procedure fields or vocabulary changes.
- Changes to existing fixture output unrelated to voter identifiers.

## Success Criteria

- A RED-to-GREEN regression test covers all five credential-form mappings.
- The registered voting-procedure golden is byte-stable and exposes the
  identifier triple block.
- `nix develop --quiet -c just ci` and the repository commit gate pass on the
  reviewed slice.
