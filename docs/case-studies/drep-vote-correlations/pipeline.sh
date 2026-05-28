#!/usr/bin/env bash
# Fetch each transaction's CBOR by txid from Koios and emit a merged
# lattice.ttl via `tx-graph --provider koios` — no intermediate cbor/ dir.
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
