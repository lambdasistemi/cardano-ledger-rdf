# Spec — Rename, transactions.ttl move, vocab IRI re-host

Issue: [#19](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/19)
Status: in progress

## Why

`cardano-rdf` claims the whole "Cardano + RDF" surface but scopes to ledger-level data (Conway tx wire format). Neighbour ontologies in `cardano-knowledge-maps` — CIP-1694 governance, smart contracts, applications, project budget instance data — are not ledger data and stay there. The honest name is `cardano-ledger-rdf`. Repo renamed already (GitHub redirect handles existing URLs). This spec covers the remaining work: import the `transactions.ttl` vocabulary into the renamed repo, re-host the vocab IRI to its new GitHub Pages URL, and sweep every internal reference to the old repo name and IRI.

## P1 user story

As an operator querying tx-graph output with SPARQL, I want the emitted vocabulary IRI (`https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#`) to dereference at the same URL where the schema is hosted, so a reasoner or human consumer can fetch the ontology and validate the predicates I use without indirection through an unrelated umbrella repo.

## Other user stories

- As a contributor reading the repo, the cabal package name, README, and source-level repo-name references all match the GitHub repo name.
- As a `cardano-knowledge-maps` maintainer, `data/rdf/transactions.ttl` lives where the tx-graph emitter lives — not in my repo where it has no consumers.
- As a CI / docs consumer, the GitHub Pages site at `lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano` returns the schema with `Content-Type: text/turtle` and a stable URL.

## Functional requirements

- **FR-1 — Repo name sweep.** Every reference to `cardano-rdf` as a *repo name* (URLs, GH workflow inputs, cabal package, README, mkdocs site name, AGENTS.md, CLAUDE.md, CHANGELOG, spec files, source-string repo identifiers) is updated to `cardano-ledger-rdf`. The vocab IRI is NOT changed by this requirement.
- **FR-2 — Cabal package rename.** `cardano-rdf.cabal` becomes `cardano-ledger-rdf.cabal`; `name:` field updated; `cabal.project` and `flake.nix` flake-output references aligned.
- **FR-3 — transactions.ttl import.** `data/rdf/transactions.ttl` from `cardano-knowledge-maps` is copied into this repo at `vocab/cardano/transactions.ttl` (or equivalent path that MkDocs serves at `/vocab/cardano`). Provenance comment preserved.
- **FR-4 — MkDocs / GH Pages serving.** The MkDocs build emits the transactions.ttl file at a path that dereferences as `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano` with `Content-Type: text/turtle`.
- **FR-5 — Vocab IRI swap.** The `cardanoPrefix` constant in `src/Cardano/Tx/Graph/Emit/Vocab.hs` and every other place the literal `https://lambdasistemi.github.io/cardano-knowledge-maps/vocab/cardano#` appears in source or fixtures is updated to `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#`.
- **FR-6 — Goldens regenerated.** All ~38 `test/fixtures/tx-graph/*/expected*.ttl` files use the new prefix; regeneration happens via the harness (not hand-edited) where possible.
- **FR-7 — Companion PR in cardano-knowledge-maps.** A separate PR in `cardano-knowledge-maps` removes `data/rdf/transactions.ttl` and replaces it with a one-line redirect/move note. The companion PR stays draft until this repo's PR merges.
- **FR-8 — Tests pass.** `nix build .#checks.x86_64-linux.*` is green at HEAD of every accepted slice.

## Success criteria

- `tx-graph` invoked on a sample mainnet CBOR emits Turtle with the new prefix `https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#`.
- That URL returns the transactions.ttl content with `text/turtle` content type when fetched.
- `nix build .#checks.*` green.
- All 1,688-tx lattice fixtures, ad-hoc smoke runs, and goldens use the new IRI.
- The companion PR in `cardano-knowledge-maps` is open (draft) with the removal diff.

## Out of scope

- Decoder typing work (covered by the 12 audit-derived tickets #3–#14).
- Migrating other tx-tools issues beyond the 4 already handled.
- Renaming `cardano-knowledge-maps` itself; it remains the home for governance/application/budget ontologies.
- Generic redirect plumbing on GitHub Pages for the OLD IRI — GH Pages doesn't redirect arbitrary paths reliably; consumers of the old prefix will need to migrate.
