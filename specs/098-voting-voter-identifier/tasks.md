# Tasks: resolvable voting-procedure voter identifiers

**Branch**: `feat/98-voting-voter-identifier` · **Plan**: [plan.md](plan.md)

## Planning

- [X] T098-P0 Read issue #98, the constitution, existing voter emission, and
  fixture registration points; record the spec, mapping, plan, and task
  contract in this commit.

## Slice S1 — Identifier emission and voting-procedure golden

- [X] T098-S1 Add a failing focused proof for each key/script/pool voter
  mapping and a registered golden fixture for a voting-procedure transaction.
- [X] T098-S1 Route the three voter forms through
  `resolveCredentialAndIntroduceIdent` with `CommitteeHotKey`,
  `CommitteeHotScript`, `DRepKey`, `DRepScript`, or `PoolId` as applicable,
  while preserving the voter class and predicate shape.
- [X] T098-S1 Regenerate the new golden only; verify existing golden fixtures
  have no unrelated diff.
- [X] T098-S1 Run focused tests, `just unit`, `./gate.sh origin/main..HEAD`,
  `nix develop --quiet -c just ci`, and the issue-named Nix checks
  (`build`, `unit`, `lint`, `vocab-validate`, `vocab-owl-smoke`); commit
  `feat: type voting-procedure voter identifiers` with `Tasks: T098-S1`.

## Finalization

- [ ] T098-F1 Audit the draft PR body, label and assignee, local gate evidence,
  and CI status; mark ready only after all implementation tasks are checked.
