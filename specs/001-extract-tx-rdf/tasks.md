# Tasks: Extract Transaction RDF Surface

**Input**: Design documents from `/specs/001-extract-tx-rdf/`
**Prerequisites**: `spec.md`, `plan.md`

## Phase 1: Bootstrap

- [X] T001 Create `lambdasistemi/cardano-rdf` with `gh`.
- [X] T002 Initialize Spec Kit and write the project constitution.
- [X] T003 Add AGENTS/README/CHANGELOG/docs bootstrap.
- [X] T004 Enable GitHub Actions write permission and standard labels.
- [X] T005 Add operator note for `CACHIX_AUTH_TOKEN`, `TAP_TOKEN`, and
  `RELEASE_BOT_SSH_KEY` secret setup.

## Phase 2: Additive Migration

- [X] T006 Copy tx RDF source, apps, tests, fixtures, docs, rules, views, Nix,
  and CI from `/code/cardano-tx-tools`.
- [X] T007 Adapt repository metadata from `cardano-tx-tools` to `cardano-rdf`.
- [X] T008 Preserve or document compatibility debt for old package/module names.
- [X] T009 Ensure docs include the migrated RDF pages and the secrets note.

## Phase 3: Verification

- [X] T010 Run Haskell build for migrated components.
- [X] T011 Run unit/golden tests covering graph and view behavior.
- [X] T012 Run strict docs build.
- [X] T013 Run cabal check.
- [X] T014 Run old-source stop check:
  `git -C /code/cardano-tx-tools status --short`.

## Phase 4: Stop Point

- [X] T015 Commit and push the working `cardano-rdf` branch.
- [X] T016 Report verification evidence and explicitly stop before deleting old
  source.

## Notes

- Do not remove files from `/code/cardano-tx-tools` in this slice.
- Do not populate GitHub secrets from the agent session.
