# Tasks: Auxiliary Data Body + isValid RDF

**Input**: `specs/017-auxiliary-data-isvalid/spec.md` and `plan.md`
**Task ID**: `T017-S1`

## Setup

- [X] T001 Read repository constitution and worker brief.
- [X] T002 Create Spec Kit scaffold for issue #17.
- [X] T003 Append WIP milestones as work progresses.

## Tests First

- [X] T004 Add fixture coverage for an auxiliary-data transaction.
- [X] T005 Add fixture coverage for an `IsValid False` transaction.
- [X] T006 Add focused unit assertions for auxiliary raw bytes and false
  validity emission.

## Implementation

- [X] T007 Add boolean literal support to graph IR, Turtle/JSON-LD
  serializers, and bounded parsers.
- [X] T008 Wire `isValidTxL` into `Cardano.Tx.Graph.Emit.Project`.
- [X] T009 Wire `auxDataTxL` into `Cardano.Tx.Graph.Emit.Project` using the
  opaque raw-CBOR leaf shape.
- [X] T010 Declare `cardano:isValid`, `cardano:hasAuxiliaryData`, and
  `cardano:AuxiliaryData` in vocab sources.
- [X] T011 Extend gate task trailer regex with `T017-S1`.

## Polish

- [X] T012 Regenerate affected transaction goldens.
- [X] T013 Run unit and Nix verification commands.
- [X] T014 Commit as `feat(tx): emit auxiliary data body + isValid flag`
  with trailer `Tasks: T017-S1`.
