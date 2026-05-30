# tx-graph (deprecated)

!!! warning "Deprecated compatibility symlink"
    `tx-graph` is a one-release compatibility symlink to
    [`cq-rdf body`](cq-rdf.md#body). New work should target the
    `cq-rdf` subcommands directly. The symlink will be removed in a
    follow-up release once downstream consumers have migrated.

Under epic
[#66](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/66)
the previous `tx-graph` CLI was split into four orthogonal subcommands
under the new `cq-rdf` binary. Today's `tx-graph` executable forwards
every invocation to `cq-rdf body` so existing scripts and packaged
binaries continue to work for one release.

## Migration

| Old invocation | New invocation |
|---|---|
| `tx-graph tx.cbor` | `cq-rdf body tx.cbor` |
| `tx-graph --provider blockfrost --token "$T" <txid>` | `cq-rdf body --provider blockfrost --token "$T" <txid>` |
| `tx-graph --rules overlay.yaml > overlay.ttl` | `cq-rdf overlay --in overlay.yaml > overlay.ttl` |
| `tx-graph --rules overlay.yaml tx.cbor > tx.ttl` | `cq-rdf overlay --in overlay.yaml > overlay.ttl` then `cq-rdf body tx.cbor > body.ttl` then `cat overlay.ttl body.ttl` |

The split is the point of the epic: separating overlay emission from
body emission removes the blank-node inflation that `--rules` caused
when it was repeated on every per-transaction call, and it makes the
typed-decode (`cq-rdf blueprint`) and SHACL validation
(`cq-rdf shacl`) passes available as independent stages.

`tx-graph --rules X` continues to emit overlay TTL via the compat
shim, but the call shape conflates three jobs (overlay, body, decode)
and is documented to be removed.

## See also

- [`cq-rdf`](cq-rdf.md) — the canonical CLI surface.
- [`overlay.yaml`](overlay-yaml.md) — the operator overlay format.
- Epic [#66](https://github.com/lambdasistemi/cardano-ledger-rdf/issues/66)
  for the architectural rationale.
