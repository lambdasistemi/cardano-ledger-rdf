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

tx-graph --rules "$SCRIPT_DIR/rules.yaml" --in-dir "$OUT/cbor" --out "$OUT/lattice.ttl"

python3 - "$OUT/lattice.ttl" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")


def hex_if_needed(value):
    if re.fullmatch(r"[0-9a-f]+(?::[0-9]+)?", value):
        return value
    if ":" in value:
        raw, index = value.rsplit(":", 1)
        return f"{raw.encode('latin-1').hex()}:{index}"
    return value.encode("latin-1").hex()


def bytes_hex_repl(match):
    return f'{match.group(1)}"{hex_if_needed(match.group(2))}"'


text = re.sub(
    r'(cardano:bytesHex )"([^"]*)"',
    bytes_hex_repl,
    text,
)
path.write_text(text, encoding="utf-8")
PY
