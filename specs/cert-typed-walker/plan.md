# Implementation Plan: Typed Certificate Walker

## Status

**Completed**: Spec scaffold, typed walker, fixture coverage, vocabulary, and verification.
**Current**: Ready for commit.
**Blockers**: None.

## Technical Context

**Language/Version**: Haskell, GHC 9.12.3 via Nix.
**Primary Dependencies**: cardano-ledger-api/conway/core, Hspec golden tests.
**Testing**: `just unit`, vocab validation, OWL smoke, branch gate.
**Constraints**: Deterministic RDF, stable bnode naming, traceable vocabulary,
single bisect-safe commit.

## Approach

Add `Cardano.Tx.Graph.Emit.Certificate`, following the native-script walker
pattern: one private shared walker consumes a root certificate bnode and the
Project resolver, while `Project.buildCertCluster` dispatches supported Conway
variants into it.

The slice is intentionally single-commit because all four ticket scopes share
one CDDL surface and one certificate dispatch point. Splitting stake, DRep,
pool, and committee support would keep reworking the same fallback branch and
would make intermediate commits less useful to bisect.

## Design Notes

- Certificate root bnodes keep the existing `certN` naming.
- Child nodes are root-derived: pool params, relays, metadata, anchors, and
  aggregate DRep targets cannot collide across certificate positions.
- Credential and hash leaves use the existing identifier resolver so entity
  overlays and raw `cardano:Identifier` nodes remain consistent.
- Anchor predicates reuse the existing `cardano:Anchor`,
  `cardano:anchorUrl`, and `cardano:anchorHash` terms.

## Risks

- `pool_params` is a large record; fixture coverage must include relays and
  metadata to keep predicate ordering and optional fields honest.
- Existing fixtures with typed certs will change from opaque fallback to rich
  triples, causing a golden cascade limited to cert-bearing transactions.
- New vocabulary terms must be reflected in the canonical fixture vocabulary
  or strict traceability will fail.

## Verification

1. Generate/update goldens with `EMIT_GOLDEN_REGEN=1 nix develop --quiet -c just unit`.
2. Run `nix develop --quiet -c just unit`.
3. Run requested Nix checks.
4. Run `./gate.sh origin/main..HEAD`.
