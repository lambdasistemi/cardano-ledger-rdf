# cardano-rdf Specs

This directory contains active Spec Kit artifacts for `cardano-rdf`.

The active migration spec is:

- `001-extract-tx-rdf/` — additive extraction of the transaction RDF
  graph, fetch, and view surface into this repository.

Historical `cardano-tx-tools` specs for downstream transaction
applications and their internal implementation tickets are intentionally
not copied here. Those specs belong to the downstream tools repository
or to its historical archive.

Future specs in this repository must describe generic Cardano RDF
vocabulary, graph extraction, packaged views, export surfaces, or
explicit hosted-service boundaries. Downstream transaction applications
can depend on this repository, but their specs should not live here.
