# Feature Specification: Author/auditor value-proposition documentation

**Feature Branch**: `docs/author-auditor-pivot`  
**Created**: 2026-06-09  
**Status**: Draft  
**Input**: Pivot the repository's README and docs to lead with the UX of two personas — transaction authors and lattice auditors — supported by app-developer-parametrized RDF assets. (Numbering note: 063–066 are reserved for the conformance epic's technical specs — typed metadata, mirror shapes, hygiene shapes, conformance harness; 067 owns the two-persona UX/presentation, of which this documentation pivot is the first deliverable.)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A reader understands what the project is for (Priority: P1)

A developer or auditor landing on the README or docs home learns, in the
first screen, that the project turns any Cardano transaction into an RDF
graph two people can use — a **transaction author** checking a tx against
an application's rules before signing, and an **auditor** querying and
classifying on-chain activity — and that the bridge between the generic
engine and a specific application is a bundle of RDF assets the app
developer ships.

**Why this priority**: The value proposition is the project's front door.
Today it reads as a "graph/RDF backend" tool list; the pivot reframes it
around who benefits and how.

**Independent Test**: A first-time reader of `README.md` / `docs/index.md`
can, without prior context, state the two personas and name the four
asset slots.

**Acceptance Scenarios**:

1. **Given** the README, **When** a reader skims the first section,
   **Then** the author and auditor personas and the app-asset bundle are
   the lead, not the tool inventory.
2. **Given** the docs site, **When** a reader opens "For app developers",
   **Then** the four asset slots (overlay / blueprints / metadata schemas
   / shapes) and the mirror-vs-hygiene shape distinction are explained.

### Edge Cases

- The framing must stay **generic** — no reader should conclude the
  engine is treasury- or Amaru-specific; Amaru appears only as the canary.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `README.md` and `docs/index.md` MUST lead with the author
  and auditor personas on one graph + one engine.
- **FR-002**: The docs MUST include a "For app developers" page describing
  the four parametrizing asset slots and the mirror-vs-hygiene shape
  distinction, reachable from the site navigation.
- **FR-003**: The tool reference (`cq-rdf`) and the case-studies index
  MUST echo the two-persona framing and point to the concept page.
- **FR-004**: All framing MUST remain generic; application-specific
  meaning is attributed to app assets, with Amaru cited only as the
  canary case study.

### Constitution Alignment *(mandatory)*

- **CA-001**: Documentation/presentation surface of the generic Cardano
  RDF product. No code or graph-output change.
- **CA-002**: No vocabulary, namespace, subject-naming, predicate, or
  golden impact — prose and navigation only.
- **CA-003**: N/A — offline; documentation only.
- **CA-004**: N/A — no migration or source deletion.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reader can name the two personas and the four asset slots
  from the README's first section alone.
- **SC-002**: The "For app developers" page is reachable in one click from
  the docs navigation.
- **SC-003**: No generic-core page asserts treasury/Amaru semantics as the
  product (Principle III), verifiable by review.

## Assumptions

- This spec covers the **documentation** deliverable only; the runnable
  two-persona demo and report rendering are separate work under the same
  067 umbrella, scheduled after the conformance epic's technical specs
  (063–066) land.
- The asset-slot list names `metadata schemas` as *(landing)* because the
  `cq-rdf metadata` slot is delivered by spec 063.
