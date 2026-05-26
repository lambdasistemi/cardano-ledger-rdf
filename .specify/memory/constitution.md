<!--
Sync Impact Report
Version change: 1.0.0 -> 1.0.1
Modified principles:
- Architecture Boundaries: clarified current Cardano.Tx.* migration namespace
Added sections: none
Removed sections: none
Templates requiring updates:
- updated: .specify/templates/plan-template.md
- updated: .specify/templates/spec-template.md
- updated: .specify/templates/tasks-template.md
- reviewed: AGENTS.md
- reviewed: README.md
- reviewed: docs/index.md
Follow-up TODOs: none
-->

# cardano-rdf Constitution

## Core Principles

### I. Cardano RDF Is The Product Boundary

This repository owns generic Cardano RDF vocabulary, graph extraction,
serialisation, packaged views, and bundle/export surfaces. Transaction RDF
is the first deliverable, but the repository name and architecture MUST
leave room for ledger state, governance, metadata, scripts, stake credentials,
and other Cardano RDF domains. `cardano-tx-tools` is a downstream consumer
and compatibility surface, not the owner of the full RDF engine.

### II. Stable Vocabulary And Reproducible Graphs

RDF output MUST be deterministic for the same inputs: stable subject naming,
stable predicate order, stable list encoding, and byte-stable Turtle goldens
unless a spec explicitly approves vocabulary drift. Vocabulary terms MUST be
documented, versioned, and traceable from tests to docs. Any intentional
change to a public term, namespace, or triple shape MUST update fixtures,
docs, and migration notes in the same slice.

### III. Generic Core, Explicit Extensions

Core packages MUST model Cardano concepts, not Amaru or treasury business
semantics. The core may know transactions, inputs, outputs, addresses,
assets, metadata, datums, witnesses, certificates, governance actions,
scripts, slots, and provenance. It MUST NOT bake in treasury scopes,
Amaru registry assumptions, or hosted-tenant names. Amaru is allowed only as
a canary configuration, fixture source, or downstream extension package.

### IV. Offline Determinism, Explicit Network Boundaries

Pure graph emission and packaged views MUST run offline from caller-provided
CBOR, rules, Turtle, and fixture files. Network access is opt-in and named:
fetchers, indexers, HTTP services, Blockfrost-compatible clients, and N2C
clients must expose explicit flags/config and record provenance. No component
may silently fall back from local input to remote lookup.

### V. Hackage-Ready Haskell Packages

Every package must remain Hackage-ready:

- `cabal check` passes with no errors or warnings.
- Haddock exists on every exported function and type.
- Modules have canonical Haddock headers.
- Package metadata includes homepage, bug-reports, license, category,
  synopsis, description, and bounded dependencies.
- `README.md` and `CHANGELOG.md` are listed in `extra-doc-files`.

### VI. Spec-First, Test-Driven, Verified Changes

Every behavior-changing slice MUST go through Spec Kit:
constitution -> spec -> plan -> tasks -> implementation. Tests are not
optional for behavior changes: write the failing test or golden first, verify
it fails for the intended reason, then implement the smallest passing change.
No completion claim is valid without a fresh verification command run after
the last edit.

### VII. Migration Without Premature Deletion

Extraction from `cardano-tx-tools` MUST be additive until the new repository
has working code, docs, tests, and CI. Move/copy source, docs, fixtures,
views, rules, and specs needed by the RDF surface; make them pass here; then
STOP before deleting old source. Removing old source or replacing it with
compatibility wrappers is a separate, explicitly reviewed follow-up.

## Operational Constraints

- GHC 9.12.3 via `haskell.nix` (`compiler-nix-name = "ghc9123"`).
- Cabal is the package source of truth; Nix wraps it for development,
  CI, release artifacts, and documentation.
- `nix flake check` is the CI gate. `just ci` MUST run the same logical
  checks locally: build, unit/golden tests, format check, hlint, docs build,
  and `cabal check`.
- Haskell formatting uses fourmolu with the org standard 70-column config;
  `cabal-fmt` owns `.cabal` formatting.
- CI jobs run on the `nixos` self-hosted runner and use
  `cachix/cachix-action@v17`; secrets are populated by an operator, never by
  an agent.
- Documentation is part of the product. When a feature moves, its user docs,
  architecture docs, examples, SPARQL views, asciinema scripts, and fixture
  notes move with it.
- GitHub Pages documentation uses MkDocs Material with light/dark palette
  support and strict builds.
- Released binaries that perform HTTPS MUST set a default `SSL_CERT_FILE`
  through a Nix wrapper and carry `cacert` in their closure.

## Architecture Boundaries

The first package surface is transaction RDF:

- Library modules currently live under `Cardano.Tx.Graph.*` and
  `Cardano.Tx.View.*`; this is deliberate migration debt recorded in the
  README. A future move to `Cardano.Rdf.*` MUST be planned as a
  compatibility-preserving release change with migration notes.
- Executables for generic RDF workflows: graph emission, closure fetch,
  packaged views, and bundle/export commands.
- RDF fixtures under `test/fixtures/`, SPARQL projections under `views/`,
  operator rules under `rules/`, and vocabulary docs under `docs/`.

Future package surfaces may include `Cardano.Rdf.Ledger`,
`Cardano.Rdf.Governance`, `Cardano.Rdf.Metadata`, and
`Cardano.Rdf.Script`. They must depend on shared RDF primitives rather than
duplicating serializers or vocabulary machinery.

Hosted services are allowed only after the library/CLI contract is stable.
The Amaru deployment is a canary tenant/configuration, not a special case in
core modules.

## Development Workflow

- Start every ticket with a spec and update the constitution first when the
  proposed work would violate or extend it.
- Keep commits vertical and bisect-safe. No WIP/fixup commits on `main`.
- Pull requests are drafts until local verification has passed.
- Use `gh` for repository setup and PR/issue operations. Do not populate
  secrets from an agent session; instead leave exact operator commands.
- Before any migration deletion in the source repository, provide a deletion
  plan, prove replacement commands work from this repository, and wait for
  explicit approval.

## Governance

This constitution supersedes informal practice. Plans, task lists, code
reviews, and release decisions MUST cite or satisfy these principles. Changes
to this file require a dedicated commit or PR, a version bump, and a short
entry in `CHANGELOG.md`.

Versioning follows semantic governance:

- MAJOR for removing or redefining a principle.
- MINOR for adding a principle or materially expanding constraints.
- PATCH for clarifications that do not change obligations.

**Version**: 1.0.1 | **Ratified**: 2026-05-26 | **Last Amended**: 2026-05-26
