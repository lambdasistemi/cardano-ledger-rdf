# Case Studies

Case studies use a common layout so dataset selection, reproducible
pipeline artifacts, presentation prose, and executable SPARQL evidence stay
separate.

```text
docs/case-studies/<slug>/
├── selection.md        # Koios transaction-selection method
├── selections.txt      # one selected txid per line
├── rules.yaml          # tx-graph entity naming rules
├── pipeline.sh         # downloads CBORs and emits lattice.ttl
├── case.md             # operator-facing presentation
├── blueprints/         # optional CIP-57 files referenced by rules.yaml
└── queries/
    └── q-example.md    # one page per query: answer, SPARQL, result
```

Use the template files as the starting point for new case studies:
[presentation](./_template/case.md),
[selection](./_template/selection.md),
[rules](./_template/rules.yaml),
[pipeline](./_template/pipeline.sh),
[selections](./_template/selections.txt), and
[query page](./_template/queries/q-example.md). Keep `pipeline.sh`,
`selections.txt`, `rules.yaml`, and any referenced blueprint files in the
case-study directory so they ship with the built site, but leave them out of
MkDocs navigation.

## Existing case studies

- [9-IO 2026 budget vote process](2026-io-budget-vote/case.md)
- [DRep vote correlations across governance actions](drep-vote-correlations/case.md)
