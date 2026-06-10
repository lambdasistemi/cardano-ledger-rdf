# Quickstart: typed metadata projection

Once 063 lands, the pipeline gains a `metadata` stage that turns the
generic metadatum tree (062) into typed `treasury:` predicates for known
labels — driven entirely by an operator schema, no code change per app.

## 1. Project typed metadata

```bash
cq-rdf body --in tx-fe2eebc8.cbor \
  | cq-rdf metadata --schemas docs/case-studies/2026-05-amaru-treasury/schemas/ \
  > typed.ttl
```

`typed.ttl` now carries, additively over the unchanged 062 tree:

```turtle
_:tx treasury:event "disburse" ;
     treasury:registryInstance "7d275cf8…f9888" ;
     treasury:justification "Agreed contract funding, …" ;   # joined from 5 chunks
     … .
```

## 2. Read a field by name (auditor UX)

```sparql
PREFIX treasury: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#>
SELECT ?event ?instance WHERE {
  ?tx treasury:event ?event ;
      treasury:registryInstance ?instance .
}
```

```bash
arq --data typed.ttl --query fields.rq     # → "disburse", "7d275cf8…f9888"
```

Compare with 062, where the same `event` needed a four-hop
`hasMetadatum → metadatumValue → hasEntry → metaKey/metaValue` walk.

## 3. Target by metadata class + check the registry hash (065 preview)

The two primitives the hygiene army needs are now one hop away:

```sparql
PREFIX treasury: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/treasury#>
# a hygiene shape (spec 065) targets contingency disburses and asserts the
# registry hash is the correct (non-typo) value:
ASK {
  ?tx treasury:event "disburse" ;
      treasury:registryInstance "7d275cf8c09fd91e73879993ef13cb73915196478d5e3777992f9888" .
}
```

A tx whose `instance` carried the upstream typo (`…f988`, missing a digit)
fails this `ASK` — the exact check 063 makes possible.

## 4. The full pipeline

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider blockfrost < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl \
  | cq-rdf blueprint --blueprints blueprints/ \
  | cq-rdf metadata  --schemas    schemas/ \
  > package.ttl
cq-rdf shacl --shapes shapes/ < package.ttl
```

`metadata` slots between `blueprint` and `shacl`: typed datums and typed
metadata are both in the graph before the shapes run.
