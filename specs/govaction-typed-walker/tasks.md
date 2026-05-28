# Tasks — Typed governance-action walker

## Slice T005-S1 — ParameterChange

- [X] T005-S1 — add `Cardano.Tx.Graph.Emit.GovAction` and wire non-treasury proposal dispatch through it
- [X] T005-S1 — emit typed `ParameterChange` and `ProtocolParamUpdate` blocks while preserving raw fallback bytes
- [X] T005-S1 — declare emitted parameter-change classes and predicates in the vocabulary and canonical pin
- [X] T005-S1 — add and regenerate fixture `29-govaction-parameter-change`

## Slice T006-S1 — UpdateCommittee

- [X] T006-S1 — emit typed `UpdateCommittee` blocks with prior action, removals, additions, term limits, and quorum
- [X] T006-S1 — declare committee-update classes and predicates in the vocabulary and canonical pin
- [X] T006-S1 — add and regenerate fixture `30-govaction-update-committee`

## Slice T007-S1 — NewConstitution and HardForkInitiation

- [X] T007-S1 — emit typed `NewConstitution` blocks with constitution anchor and optional guardrail script
- [X] T007-S1 — emit typed `HardForkInitiation` blocks with protocol-version major/minor fields
- [X] T007-S1 — declare constitution and hard-fork classes and predicates in the vocabulary and canonical pin
- [X] T007-S1 — add and regenerate fixtures `31-govaction-new-constitution` and `32-govaction-hard-fork-initiation`

## Finalization

- [X] T005-S1, T006-S1, T007-S1 — `nix develop --quiet -c just unit`
- [X] T005-S1, T006-S1, T007-S1 — required Nix checks
- [X] T005-S1, T006-S1, T007-S1 — final commit passes `./gate.sh origin/main..HEAD`
