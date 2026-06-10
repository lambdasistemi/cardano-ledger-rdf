# Contract: metadata schema format + typed projection

## Schema file contract (`*.schema.json`)

- Loaded from `cq-rdf metadata --schemas DIR` (sorted by filename, like the
  blueprint loader). Each file is one schema for one `label`.
- Required keys: `label` (integer), `prefix` (string), `namespace` (IRI),
  `fields` (array). Each field: `predicate` (string), `path` (array of
  strings), `kind` (one of `text|int|bytes|joinedText|uriList`).
- A malformed schema file aborts the pass with a non-zero exit and a
  `MetadataSchemaParseError: <path>: <reason>` on stderr (mirrors
  `BlueprintParseError`).

## Worked schema — `treasury-1694.schema.json`

Ships under the Amaru case study (`docs/case-studies/2026-05-amaru-treasury/schemas/`).
See data-model.md for the full file.

## Expected typed output — contingency tx `fe2eebc8…`

After `cq-rdf body … | cq-rdf metadata --schemas …`, the transaction node
gains (additive; bnode/URI rendering illustrative):

```turtle
_:fe2eebc8 treasury:event            "disburse" ;
           treasury:label            "Contingency disburse" ;
           treasury:registryInstance "7d275cf8c09fd91e73879993ef13cb73915196478d5e3777992f9888" ;
           treasury:destination      "Core Development, Ops and Use Cases, Network Compliance treasury" ;
           treasury:justification    "Agreed contract funding, existing and new: Core dev (2 FTE: Eric, Josh from Sundae and 0.5 FTE Roland), Ops (1 FTE PM Damien, 1 FTE SPO scope Arnaud, node diversity fixed costs), Network white-hat (Jon). Target market swap 0.167; surplus above accrues to the scopes." ;
           treasury:references       <ipfs://bafkreibfgoyo5jg3ufd3jeqg2mhjo5e2wdscfpfqqei3rkb7pmndj5mzem> .
```

### Contract assertions (golden-checked)

1. **C1**: `treasury:event` = `"disburse"`, reachable in one hop from the tx
   (no `metaKey`/`metaValue` traversal).
2. **C2**: `treasury:registryInstance` = `7d275cf8…f9888` **verbatim** — the
   exact byte string spec 065's hygiene shape will equality-check against the
   correct contingency registry hash (the upstream-typo catcher).
3. **C3**: `treasury:justification` is the **single joined string** — the
   on-chain 5-chunk `MetaList` concatenated in order (the join 062 omitted),
   while the generic `cardano:MetaList` for it is **still present**.
4. **C4**: every pre-existing `cardano:` triple (incl. the full 062
   metadatum tree) is byte-identical to the pre-063 input (additivity).
5. **C5**: a query/shape can select this tx by `treasury:event` and not
   match a metadata-free tx (the targeting primitive for 065).
6. **C6**: re-running the pass twice yields byte-identical Turtle.

## Negative / edge contracts

- A tx with **no label-1694 metadata** → no `treasury:*` triples.
- A label-1694 tree **missing `body/event`** → `_:tx treasury:schemaError
  "label 1694: missing key body/event" .`, generic tree intact, no partial
  `treasury:event`.
- A field declared `joinedText` over a non-`MetaText` element →
  `treasury:schemaError`, not a coerced value.
