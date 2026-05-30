# Case Studies

Case studies use a common declarative-package layout so dataset
selection, operator overlay, optional CIP-57 blueprints, SHACL
invariants, presentation prose, and SPARQL evidence stay separate. The
reproduce step is a documented Unix pipe in each case study's
`README.md` — no per-case shell scripts, no orchestrator binaries.

```text
docs/case-studies/<slug>/
├── README.md            # documents the reproduce pipe
├── selection.md         # txid-selection method
├── selections.txt       # one selected txid per line
├── overlay.yaml         # operator overlay (entities, vendors,
│                        #   attestations, imports:)
├── blueprints/          # optional CIP-57 files for cq-rdf blueprint
├── shapes/              # optional SHACL invariants for cq-rdf shacl
├── case.md              # operator-facing presentation
└── queries/
    └── q-example.md     # one page per query: answer, SPARQL, result
```

Use the template files as the starting point for new case studies:
[README](./_template/README.md),
[presentation](./_template/case.md),
[selection](./_template/selection.md),
[overlay](./_template/overlay.yaml),
[selections](./_template/selections.txt), and
[query page](./_template/queries/q-example.md). Keep `README.md`,
`selections.txt`, `overlay.yaml`, and any referenced blueprint or shape
files in the case-study directory so they ship with the built site, but
leave them out of MkDocs navigation when they aren't reader-facing.

## Existing case studies

- [9-IO 2026 budget vote process](2026-io-budget-vote/case.md)
- [DRep vote correlations across governance actions](drep-vote-correlations/case.md)
- [Amaru Treasury May 2026](2026-05-amaru-treasury/case.md)
