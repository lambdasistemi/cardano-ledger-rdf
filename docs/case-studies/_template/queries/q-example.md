# Q1 - Example question

One sentence gives the observed answer and the count or value that the
query produces.

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
SELECT (COUNT(*) AS ?n)
WHERE {
  ?s ?p ?o .
}
```

Observed result:

```text
n = 0
```
