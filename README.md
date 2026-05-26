# cardano-rdf

Generic Cardano RDF vocabulary, transaction graph extraction, packaged views,
and export tooling.

The first package surface is transaction RDF: Conway transaction CBOR plus
operator rules to deterministic Turtle/JSON-LD, with packaged views over the
canonical graph. `cardano-tx-tools` is expected to consume this repository as
a downstream compatibility layer.

## Development

```bash
nix develop --quiet
just --list
just ci
```

The repository uses Spec Kit. Start with the constitution in
`.specify/memory/constitution.md` before writing specs or implementation.

## Secrets

Agents must not populate repository secrets. Operators can populate the
required Cachix secret with:

```bash
gh secret set CACHIX_AUTH_TOKEN \
  --repo lambdasistemi/cardano-rdf \
  --body "$CACHIX_AUTH_TOKEN"
```

Verify with:

```bash
gh secret list --repo lambdasistemi/cardano-rdf
```

## License

Apache-2.0.
