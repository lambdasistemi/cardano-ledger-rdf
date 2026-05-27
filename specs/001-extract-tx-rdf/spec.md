# Feature Specification: Extract Transaction RDF Surface

**Feature Branch**: `001-extract-tx-rdf`  
**Created**: 2026-05-26  
**Status**: Draft  
**Input**: Extract transaction RDF graph, fetch, view, rules, fixtures, and docs from `cardano-tx-tools` into `cardano-rdf` without deleting the old source.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Build Tx RDF In New Repo (Priority: P1)

As a Cardano RDF maintainer, I can build and run the existing transaction RDF
pipeline from `cardano-rdf` so this repository becomes the owner of the graph
engine before any old source is removed.

**Why this priority**: The new repo must prove it can own the working code
before `cardano-tx-tools` changes.

**Independent Test**: Build `tx-graph`, run it against an existing CBOR/rules
fixture, and compare the emitted Turtle with the migrated golden.

**Acceptance Scenarios**:

1. **Given** migrated source and fixtures, **When** `tx-graph` is built and run
   on a tx-graph fixture, **Then** the emitted Turtle matches the
   expected `.ttl`.
2. **Given** a lattice directory of CBOR files, **When** `tx-graph --in-dir`
   runs, **Then** it writes one deterministic `.ttl` per transaction.

---

### User Story 2 - Move Docs With The Surface (Priority: P1)

As an operator, I can read `cardano-rdf` documentation for `tx-graph`,
`tx-fetch`, `tx-view`, lattice workflows, rules, prior art, and RDF fixtures
without opening `cardano-tx-tools`.

**Why this priority**: Documentation is part of the migration contract; moving
code alone leaves operators on the wrong source of truth.

**Independent Test**: Build MkDocs strictly in `cardano-rdf`.

**Acceptance Scenarios**:

1. **Given** migrated docs, **When** the docs site builds, **Then** links to
   migrated RDF pages resolve inside `cardano-rdf`.
2. **Given** a secrets/setup page, **When** an operator reads it, **Then** it
   shows the exact `gh secret set CACHIX_AUTH_TOKEN` command and states agents
   do not populate secrets.

---

### User Story 3 - Stop Before Old Source Deletion (Priority: P1)

As the migration owner, I can verify that `cardano-tx-tools` still contains
the original source and no deletion has been staged there.

**Why this priority**: The user explicitly requested a stop point before
deleting the old source.

**Independent Test**: Check `git -C /code/cardano-tx-tools status --short` and
verify no tracked source deletion is present.

**Acceptance Scenarios**:

1. **Given** the new repo passes its verification gate, **When** the migration
   pauses, **Then** `cardano-tx-tools` has no source deletions staged.
2. **Given** a future deletion is desired, **When** it is planned, **Then** it is
   handled as a separate reviewed slice.

### Edge Cases

- Existing docs reference `cardano-tx-tools` URLs; migrated docs must either
  update URLs to `cardano-rdf` or explicitly mark historical links.
- Existing package/module names may need a compatibility phase; any retained
  `Cardano.Tx.*` public module names must be documented as migration debt.
- Networked `tx-fetch` requires `BLOCKFROST_PROJECT_ID`; tests must not require
  a live secret.
- The first repo CI cannot use Cachix until an operator runs the documented
  secret setup command.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST contain the transaction RDF graph emitter,
  rules loader, serializers, packaged views, fetcher, tests, fixtures, rules,
  views, and docs needed to operate the RDF pipeline.
- **FR-002**: The repository MUST build the migrated Haskell components from
  its own Cabal/Nix files.
- **FR-003**: The repository MUST build docs strictly with MkDocs.
- **FR-004**: The repository MUST keep networked fetch behavior explicit and
  must not require repository secrets for unit/golden verification.
- **FR-005**: The migration MUST leave `/code/cardano-tx-tools` source files in
  place and unstaged for deletion.
- **FR-006**: The repository MUST include an operator note with the exact
  `gh secret set CACHIX_AUTH_TOKEN --repo lambdasistemi/cardano-rdf` command.
- **FR-007**: The spec/plan/tasks MUST record retained compatibility debt if the
  first working copy preserves old package or module names.

### Key Entities *(include if feature involves data)*

- **Tx RDF graph**: Deterministic triples describing transactions, inputs,
  outputs, assets, metadata, datums, witnesses, certificates, governance, and
  provenance.
- **Rules overlay**: Turtle/YAML operator-authored entities, labels, imports,
  blueprints, and attestations merged with graph output.
- **Packaged view**: A named projection over canonical Turtle, such as
  `cli-tree`, `asset-flow`, `entity-occurrences`, or `json-ld`.
- **Lattice**: A closed or partially closed set of transaction CBOR files used
  for parent-input resolution during graph emission.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `tx-graph`, `tx-view`, and `tx-fetch` build in `cardano-rdf`.
- **SC-002**: Migrated unit/golden tests for graph and view behavior pass.
- **SC-003**: `mkdocs build --strict` passes.
- **SC-004**: `git -C /code/cardano-tx-tools status --short` shows no source
  deletions caused by this migration.

## Assumptions

- First migration may preserve old Haskell module names temporarily to keep the
  copy verifiable; namespace cleanup can be a follow-up if documented.
- Amaru remains fixture/canary material only and is not introduced as a core
  semantic dependency.
- The immediate goal is additive extraction, not removal from
  `cardano-tx-tools`.
