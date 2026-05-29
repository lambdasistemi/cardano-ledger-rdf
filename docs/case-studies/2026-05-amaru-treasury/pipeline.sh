#!/usr/bin/env bash
# Dev artifact: emit a single SPARQL-queryable lattice.ttl for the txids in
# selections.txt by fetching each transaction's CBOR from Koios via
# `tx-graph --provider koios` — no intermediate cbor/ directory.
# Usage: [KOIOS_TOKEN=...] ./pipeline.sh <out_dir>
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT="${1:-./out}"
SELECTIONS="$SCRIPT_DIR/selections.txt"
KOIOS_TOKEN="${KOIOS_TOKEN:-}"

mkdir -p "$OUT"
: > "$OUT/lattice.ttl"

# Bodies fetched + emitted one shot per txid. --rules is passed on every
# call so each body sees the blueprint registry; without it the typed
# datum decode (OrderDatum_*) does not fire. Each per-tx invocation
# re-emits the overlay (entity declarations, blueprint registrations,
# off-chain attestations) — entity IRIs dedup as triples, but the
# attestation/off-chain-entity blank-node blocks accumulate; queries
# joining through them use SELECT DISTINCT (see Q5).
while IFS= read -r txid; do
  [ -n "$txid" ] || continue
  case "$txid" in \#*) continue ;; esac
  tx-graph --rules "$SCRIPT_DIR/rules.yaml" \
    --provider koios ${KOIOS_TOKEN:+--token "$KOIOS_TOKEN"} "$txid"
done < "$SELECTIONS" >> "$OUT/lattice.ttl"
