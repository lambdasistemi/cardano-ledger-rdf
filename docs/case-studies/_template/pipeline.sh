#!/usr/bin/env bash
# Download CBORs for selections.txt and emit a merged lattice.ttl.
# Usage: ./pipeline.sh <out_dir>
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT="${1:-./out}"
SELECTIONS="$SCRIPT_DIR/selections.txt"

mkdir -p "$OUT/cbor"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

split -l 50 "$SELECTIONS" "$TMP/chunk-"

for chunk in "$TMP"/chunk-*; do
  jq -R -s \
    '{_tx_hashes: (split("\n") | map(select(length > 0 and (startswith("#") | not))))}' \
    "$chunk" > "$TMP/body.json"

  curl -sS -X POST https://api.koios.rest/api/v1/tx_cbor \
    -H "Content-Type: application/json" \
    -d @"$TMP/body.json" \
    | jq -r '.[] | [.tx_hash, .cbor] | @tsv' \
    | while IFS=$'\t' read -r hash cbor; do
        printf '%s' "$cbor" > "$OUT/cbor/$hash.cbor"
      done
done

tx-graph --rules "$SCRIPT_DIR/rules.yaml" > "$OUT/lattice.ttl"
for f in "$OUT"/cbor/*.cbor; do
  tx-graph "$f"
done >> "$OUT/lattice.ttl"
