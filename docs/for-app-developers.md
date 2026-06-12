# For app developers

`cardano-ledger-rdf` is a **generic** engine: it knows transactions,
outputs, datums, metadata, certificates — Cardano, not your application.
You teach it your application by shipping a small bundle of **RDF
assets**. Once you do, two people get a usable experience for free, with
no bespoke tooling:

- a **transaction author** can check a transaction against your rules
  *before* signing or submitting it, and
- an **auditor** can query and classify what happened on-chain across a
  whole lattice of transactions, in your application's own terms.

Both run on the same graph and the same engine. Your assets are the only
thing that makes them speak your language.

## The asset bundle

You parametrize the engine through three slots. Each is an ordinary file
(or directory) you version and ship alongside your app — the way you
already ship a policy id or a script address.

| Asset | Consumed by | What you put in it |
|---|---|---|
| **overlay** | `cq-rdf overlay` | Your on-chain and off-chain entities, human labels, vendor/attestation links — operator/app reference data in YAML or Turtle. |
| **blueprints** | `cq-rdf blueprint` | Your CIP-57 blueprints, so datum/redeemer fields decode into typed, queryable predicates instead of opaque bytes. |
| **shapes** | `cq-rdf shacl` | SHACL constraints — both *mirror* shapes (a declarative echo of your on-chain validators) and *hygiene* shapes (rules with no on-chain twin that you nonetheless want every authored tx to satisfy). |

Transaction metadata needs no slot of its own: `cq-rdf body` decodes
every metadata label into faithful triples as part of the body graph,
so the fields inside (e.g. a governance rationale block) are already
triples a shape or query can target.

Nothing in the core knows what these mean — that is deliberate
(`cardano:` models the ledger; your meaning lives in your assets and, if
you publish a vocabulary, in your own namespace, the way the canary's
`treasury:` extension does). See [Vocabulary](vocab.md).

## The two consumers, one pipeline

The author gate and the auditor classifier are **not two tools**. They
are the same four-stage pipe, pointed at different inputs and read with
different intent:

```bash
cq-rdf overlay --in overlay.yaml > overlay.ttl
xargs -P8 -n1 cq-rdf body --provider blockfrost --token "$BLOCKFROST_PROJECT_ID" \
  < selections.txt > bodies.ttl
cat overlay.ttl bodies.ttl \
  | cq-rdf blueprint --blueprints blueprints/ \
  > package.ttl
cq-rdf shacl --shapes shapes/ < package.ttl     # author gate
arq --data package.ttl --query my.rq            # auditor query
```

### Author — a pre-sign gate

Point `cq-rdf body` at the transaction you just built. `cq-rdf shacl
--shapes` exits non-zero and prints a **readable, domain-level
violation** ("missing required co-signer middleware (97e0f6d6)") rather
than a ledger error code. A non-conforming transaction never reaches a
co-signer, so a multi-party signing round is never wasted discovering a
mistake at signer #3.

### Auditor — a lattice classifier

Point `cq-rdf body` at a lattice of on-chain txids. The **same shapes**
become a classifier: a transaction that conforms was built by your
canonical pipeline; one that violates is foreign or off-spec — anomaly
detection for free. The same package answers cross-transaction questions
through any SPARQL engine.

## Two kinds of shape

When you author the `shapes/` slot, you are writing in two registers:

- **Mirror shapes** echo your on-chain validators (e.g. "this redeemer
  requires owner + one other signer"). They are *ergonomic* — the chain
  already enforces them; the shape just fails earlier and more legibly.
  Keep them honest with a conformance test: run a corpus through both the
  shapes and the real ledger outcome and assert they agree.
- **Hygiene shapes** have **no on-chain twin**. The contract accepts a
  broad class of transactions; you choose to only ever build a narrow,
  canonical sub-class (pinned output ordering, a destination allowlist
  for a closed-recipient flow, a required attestation link). These are
  the *load-bearing* shapes: they enforce what nothing on-chain will,
  and they are self-justifying — they cannot drift, because there is
  nothing to drift from.

Scope a shape to the transaction class it governs (target by a metadata
label or a structural signature); a rule that is true for one flow must
not be asserted over all of them.

## A worked bundle

The [2026-05 Amaru treasury](case-studies/2026-05-amaru-treasury/README.md)
case study is the canary: a complete asset bundle —
`overlay.yaml`, `blueprints/`, `shapes/`, `selections.txt`, and a query
set — that drives both the author gate and the auditor classifier over a
real mainnet batch. Start a new application by copying the
[case-study template](case-studies/_template/README.md) and filling the
three slots with your own assets.
