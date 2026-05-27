# Spec — Port ontology validation gate from cardano-knowledge-maps

Closes [#40](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/40).

## Why

`lambdasistemi/cardano-ledger-rdf` now owns the `cardano:` vocabulary
(migrated from `cardano-knowledge-maps` via #19 / #21). Ownership of the
TTL implies ownership of the proofs that the TTL is well-formed and
that the OWL 2 RL axioms compose into the inferences the case studies
rely on. Today those proofs still live in the upstream repo.

This slice ports the validation gate so the vocab and its gate travel
together — operators reading the case studies can run the same checks
the CI runs.

## P1 user story

As a contributor opening a PR that touches `vocab/cardano/*.ttl`, I want
CI to refuse the merge if any of the following breaks: (a) any TTL file
under `vocab/**` fails to parse with rdflib, (b) any of the curated OWL
2 RL smoke fixtures stops matching its declared expectation, or (c) any
new `owl:Nothing` instance is inferred. The gate runs in the same
`Build Gate` job that already gates the Haskell builds.

## Other user stories

- As an operator reading a case study, I can re-run the same parser and
  reasoner the CI uses (`just vocab-validate`, `just vocab-owl-smoke`)
  without leaving the dev shell.
- As a future vocab author, the smoke directory shows how to add a new
  fixture: drop an `<name>.n3` + companion `<name>.ask` with
  `# EXPECT: true|false` comments and the harness picks them up.

## Functional requirements

- **FR-1 — Parse pass.** `just vocab-validate` rdflib-parses every TTL
  matched by `vocab/**/*.ttl` and exits 0 only if all parse. It prints
  the triple count per file.
- **FR-2 — Smoke pass.** `just vocab-owl-smoke` unions every TTL under
  `vocab/**` + the curated EYE OWL 2 RL rule subset
  (`owl-sameAs.n3`, `owl-inverseOf.n3`, `owl-hasKey.n3`,
  `owl-Nothing.n3`) + each fixture, runs EYE, parses the closure into
  rdflib, evaluates every SPARQL ASK in the fixture's companion `.ask`
  file, and fails on EXPECT mismatch or any inferred `owl:Nothing`
  instance.
- **FR-3 — Two baseline fixtures.** `test/fixtures/vocab/smoke/`
  contains at least `baseline.{n3,ask}` (RDFS subClassOf transitivity
  smoke — proves the harness pipeline) and `sameas-key.{n3,ask}`
  (`owl:hasKey` → `owl:sameAs` inference — proves the OWL 2 RL rules
  are loaded). These are copied verbatim from
  `cardano-knowledge-maps/specs/053-vocab-transactions/smoke/`.
- **FR-4 — Flake checks.** `nix build .#checks.x86_64-linux.vocab-validate`
  and `nix build .#checks.x86_64-linux.vocab-owl-smoke` succeed.
- **FR-5 — CI gate.** The existing `Build Gate` job in
  `.github/workflows/ci.yml` is extended to build the two new check
  derivations. No new job is added.
- **FR-6 — Dev shell.** The default dev shell exposes both `python3` (with
  `rdflib`) and `eye` on PATH. The repo packages `eye` locally
  (`nix/eye.nix`) rather than depending on nixpkgs.
- **FR-7 — Glob over config.** Targets are picked up by a `vocab/**/*.ttl`
  glob — no JSON config to keep in sync. New vocab files added under
  `vocab/` are gated automatically.

## Success criteria

- All FRs implemented.
- `./gate.sh origin/main..HEAD` exits 0.
- PR CI is green; `Build Gate` job exercises both new checks.

## Out of scope

- Adding new vocab files.
- Hooking the validation into the case-study `pipeline.sh` scripts.
- A SHACL conformance pass.
- Property/shape constraints beyond what OWL 2 RL provides.
