# Tasks: per-entity network literals

**Input**: Design documents from `specs/096-per-entity-network/`
**Prerequisites**: spec.md, plan.md

**Tests**: Required. This is a public RDF/vocabulary shape change.

## Slice 1 - Additive network literals

**Goal**: Emit `cardano:network` on every network-bearing address/account
surface and regenerate deterministic Turtle/vocab goldens.

- [X] T096 Add `TermNetwork` to `Vocab.hs`, declare `cardano:network` in
  `vocab/cardano/transactions.ttl`, and refresh canonical vocab fixtures.
- [X] T097 Emit `cardano:network` using `networkToWord8` on address
  decomposition subjects.
- [X] T098 Emit `cardano:network` using `networkToWord8` on withdrawal,
  proposal return, and proposal treasury-withdrawal account-bearing subjects.
- [X] T099 Regenerate Turtle goldens and verify the diff is additive with
  correct `0`/`1` values.
- [X] T100 Run focused golden, vocab, format, hlint, gate, and full CI
  verification.
- [X] T101 Commit one bisect-safe slice:
  `feat: emit per-entity network literals`

## Dependencies & Execution Order

All tasks belong to one bisect-safe slice because the vocabulary enum,
emitter, and goldens must stay consistent at HEAD.

## Parallel Opportunities

The driver owns implementation and commit. The navigator independently reviews
RED and GREEN diffs before the commit, with special attention to additive
golden changes and network value correctness.
