#!/usr/bin/env bash
# Dev artifact: download CBORs from Blockfrost for the txids in selections.txt,
# then emit a single SPARQL-queryable lattice.ttl via tx-graph.
# Usage: BLOCKFROST_PROJECT_ID=mainnet... ./pipeline.sh <out_dir>
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT="${1:-./out}"
SELECTIONS="$SCRIPT_DIR/selections.txt"
NETWORK="${BLOCKFROST_NETWORK:-mainnet}"
PROJECT_ID="${BLOCKFROST_PROJECT_ID:?set BLOCKFROST_PROJECT_ID}"

case "$NETWORK" in
  mainnet) API="https://cardano-mainnet.blockfrost.io/api/v0" ;;
  preprod) API="https://cardano-preprod.blockfrost.io/api/v0" ;;
  preview) API="https://cardano-preview.blockfrost.io/api/v0" ;;
  *) echo "unsupported BLOCKFROST_NETWORK: $NETWORK" >&2; exit 2 ;;
esac

mkdir -p "$OUT/cbor"

while IFS= read -r hash; do
  [ -n "$hash" ] || continue
  case "$hash" in \#*) continue ;; esac

  curl -sS "$API/txs/$hash/cbor" \
    -H "project_id: $PROJECT_ID" \
    | jq -r '.cbor' > "$OUT/cbor/$hash.cbor"
done < "$SELECTIONS"

tx-graph --rules "$SCRIPT_DIR/rules.yaml" --in-dir "$OUT/cbor" --out "$OUT/lattice.ttl"
