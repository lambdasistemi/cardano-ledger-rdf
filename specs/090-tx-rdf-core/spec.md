# Feature Specification: tx-rdf-core package split

**Feature Branch**: `rdf-90-tx-rdf-core`  
**Created**: 2026-06-13  
**Status**: Draft  
**Input**: User description: "Split out a lean wasm-compilable tx-rdf-core library package for cardano-ledger-rdf#90."

## User Scenarios & Testing

### User Story 1 - Lean RDF Core Consumer (Priority: P1)

Downstream consumers can depend on a lean `tx-rdf-core` package to decode
Conway transactions, emit deterministic RDF, serialize Turtle/JSON-LD, load
in-memory Turtle rules, and render packaged views without pulling CLI,
network, YAML, or filesystem-import dependencies.

**Why this priority**: This is the prerequisite for the inspector RDF
composability epic and enables wasm-facing consumers to reuse the pure
transaction RDF engine.

**Independent Test**: Build only the `tx-rdf-core` library and verify its
dependency surface excludes HTTP, YAML, optparse, directory, filepath, and
process packages.

**Acceptance Scenarios**:

1. **Given** a clean checkout, **When** only `tx-rdf-core` is built, **Then**
   the pure emit/decode/serialize/view modules compile without fat runtime
   dependencies.
2. **Given** the inspector CHaP pin dated 2026-04-15, **When**
   `tx-rdf-core` is built against that package index, **Then** it either
   compiles or the incompatibility is recorded with exact failing packages and
   modules.

---

### User Story 2 - Existing CLI Compatibility (Priority: P2)

Existing users of `cq-rdf`, `tx-view`, and the fat `cardano-ledger-rdf`
library keep the same behavior while the fat package consumes
`tx-rdf-core` internally.

**Why this priority**: The split must not regress current CLI and library
workflows.

**Independent Test**: Build and test the existing executables and golden
suite after the package split.

**Acceptance Scenarios**:

1. **Given** the existing fixture suite, **When** the emit goldens run,
   **Then** generated Turtle remains byte-identical.
2. **Given** the existing CLI entry points, **When** `cq-rdf` and `tx-view`
   build and their smoke tests run, **Then** they consume the core package
   without public behavior changes.

### Edge Cases

- Modules that appear pure but import filesystem, HTTP, YAML, optparse, or
  process APIs must remain in the fat package and be recorded as out of core.
- Tests that compile against the old single-package library must either target
  `tx-rdf-core` for pure behavior or the fat package for CLI/network/import
  behavior.
- The package split must not delete migrated source from downstream
  `cardano-tx-tools`.

## Requirements

### Functional Requirements

- **FR-001**: The repository MUST define a new `tx-rdf-core` package in this
  repository, not in a separate repository.
- **FR-002**: `tx-rdf-core` MUST expose the pure transaction RDF engine:
  `Cardano.Tx.Decode`, `Cardano.Tx.Blueprint`, `Cardano.Tx.Graph.Emit` and
  pure emit submodules, Turtle/JSON-LD serializers, triples, vocab, in-memory
  Turtle rules parsing/merge support, and `Cardano.Tx.View` modules.
- **FR-003**: `tx-rdf-core` MUST NOT depend on `http-client`,
  `http-client-tls`, `libyaml`, `yaml`, `optparse-applicative`, `directory`,
  `filepath`, or `process`.
- **FR-004**: `cardano-ledger-rdf` MUST retain provider, Web2 resolver,
  import resolver, YAML parser, and executable support, depending on
  `tx-rdf-core` for shared pure modules.
- **FR-005**: Existing `cq-rdf` and `tx-view` executables MUST build and
  behave as before.
- **FR-006**: Existing emit goldens MUST remain byte-identical unless a
  blocker is filed; this ticket does not authorize RDF vocabulary or triple
  shape changes.
- **FR-007**: Verification MUST include standalone `tx-rdf-core` build,
  dependency-surface proof, existing CLI/golden tests, `nix build`, `just ci`,
  and an inspector CHaP pin check for 2026-04-15.

### Constitution Alignment

- **CA-001**: This feature belongs to the generic Cardano RDF core and
  packaged view/export surface of this repository.
- **CA-002**: No vocabulary, namespace, subject naming, predicate ordering, or
  golden output change is intended.
- **CA-003**: Pure graph and view flows remain offline. Network boundaries stay
  in the fat provider and resolver modules.
- **CA-004**: No deletion from `cardano-tx-tools` is in scope.

### Key Entities

- **tx-rdf-core package**: Lean Cabal package containing pure transaction RDF
  modules and lean dependency bounds.
- **cardano-ledger-rdf package**: Fat Cabal package containing CLI, network,
  YAML, filesystem import, and executable support.
- **Pure module set**: Modules classified by import scan as safe for the core
  package.
- **Fat module set**: Modules that use HTTP, YAML, optparse, filesystem, or
  process APIs.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A standalone `tx-rdf-core` library build completes successfully.
- **SC-002**: The `tx-rdf-core` dependency tree contains zero HTTP, YAML,
  optparse, directory, filepath, or process packages.
- **SC-003**: Existing emit golden fixtures compare byte-identically after the
  split.
- **SC-004**: `cq-rdf` and `tx-view` build and pass their existing smoke and
  unit coverage while consuming `tx-rdf-core`.
- **SC-005**: `nix build` and `nix develop --quiet -c just ci` pass after the
  final edit.
- **SC-006**: The inspector CHaP pin check dated 2026-04-15 is either green or
  has a specific Q-file blocker.

## Assumptions

- The package split can be done by moving package ownership in Cabal metadata
  without changing module namespaces in this ticket.
- Public module names remain under `Cardano.Tx.*` to avoid a compatibility
  migration in the same change.
- Existing tests are sufficient behavior coverage for byte-stable output; new
  tests focus on package boundaries and dependency closure.
