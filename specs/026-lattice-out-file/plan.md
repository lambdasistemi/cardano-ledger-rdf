# Plan — tx-graph lattice-mode `--out FILE`

## Tech stack

- Haskell `cardano-ledger-rdf` library
- `app/tx-graph/Main.hs` — CLI parser; already accepts `--in-dir`, `--out-dir`, `--out`, `--tx`. Need to allow `--in-dir + --out` simultaneously.
- `src/Cardano/Tx/Graph/Emit.hs` and `src/Cardano/Tx/Graph/Emit/Serialize/Turtle.hs` — the body emit + serializer
- `src/Cardano/Tx/Graph/Emit/Project.hs` — where tx-position bnodes are minted (`_:input1`, `_:vote1`, `_:proposal1`, etc.)
- Goldens harness via `EMIT_GOLDEN_REGEN=1`

## Slice boundaries

One slice. The change is mechanically contained: a new emit-merge path that walks the input dir, renames per-tx-position bnodes inline, and emits one Turtle file.

### Slice — implement `--in-dir + --out FILE`

Steps:
1. CLI: allow `--in-dir` and `--out` together. The existing exclusivity check rejects this combo today — relax it.
2. Library: add a function (suggested location `Cardano.Tx.Graph.Emit.Serialize.Turtle`) that takes a lattice of `(txid, emittedTriples)` pairs and produces a single Turtle document:
   - One header (prefixes) at the top
   - For each tx, a `# === tx <txid> ===` comment then the body triples, with per-tx-position bnodes renamed to `_:<txid-short>_<originalName>`
   - Content-addressed identifier bnodes (those whose label starts with `hash_` or `cred_`) are LEFT UNCHANGED
   - Position-bnodes can be detected at the IR/bnode-name level (preferred) OR via regex on serialized output (simpler). Either works; pick whichever the existing emitter structure makes cleaner.
3. Wire the new function into the CLI's `--in-dir + --out` branch.
4. Add a goldens-harness fixture: 2-tx CBOR set with `expected.lattice.ttl`. Use existing emit-golden infrastructure.
5. Run `nix build .#checks.x86_64-linux.unit` — must stay green.
6. Verify FR-8 manually: re-run on `/tmp/io-gov-actions/cbor/` (1,688 files) and check ARQ produces the same 162,145,961 ADA sum.

Files touched:
- `app/tx-graph/Main.hs` (CLI parser + dispatch)
- `src/Cardano/Tx/Graph/Emit/Serialize/Turtle.hs` (new emit-merge function)
- `src/Cardano/Tx/Graph/Emit.hs` (re-export if needed)
- A new fixture under `test/fixtures/tx-graph/<NN>-lattice-merged/`
- `docs/tx-graph.md` (one paragraph documenting the new mode)

## Gate

```
./gate.sh origin/main..HEAD
nix build --quiet -L .#checks.x86_64-linux.unit
```

Smoke (post-build, in `nix develop`):
```
TXG=$(cabal list-bin tx-graph -O0)
"$TXG" --in-dir /tmp/io-gov-actions/cbor --out /tmp/io-gov-actions/lattice-merged.ttl
nix shell nixpkgs#apache-jena --command arq \
  --data /tmp/io-gov-actions/lattice-merged.ttl \
  --query <(echo 'PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#> SELECT (SUM(?lov) AS ?total) WHERE { ?p a cardano:Proposal ; cardano:hasGovAction/cardano:hasWithdrawal/cardano:hasLovelace ?lov }')
# expect total = 162145961000000
```
Record the smoke result in WIP.md.

## Risks

- **Bnode collision detection in the IR vs serializer**: if the existing emitter mints bnodes as `BnodeLabel "input1"` etc. before any serialization, renaming at IR level is cleaner. If they're stringly typed in the serializer, regex-on-output is simpler but more fragile. Check the IR shape first.
- **Worker's regex `_:(?!hash_|cred_)…` is a runtime-string filter**: the Haskell side should NOT need negative lookahead — it has type-level access to the bnode family. Make sure the implementation uses the typed distinction, not a string regex.
- **Byte-stability**: depends on deterministic tx ordering in the lattice (sort by filename). The existing lattice mode already sorts; verify the new path uses the same order.
