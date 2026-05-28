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

# overlay once
tx-graph --rules "$SCRIPT_DIR/rules.yaml" > "$OUT/lattice.ttl"

# bodies fetched + emitted in one shot per txid
while IFS= read -r txid; do
  [ -n "$txid" ] || continue
  case "$txid" in \#*) continue ;; esac
  tx-graph --provider koios ${KOIOS_TOKEN:+--token "$KOIOS_TOKEN"} "$txid"
done < "$SELECTIONS" >> "$OUT/lattice.ttl"
