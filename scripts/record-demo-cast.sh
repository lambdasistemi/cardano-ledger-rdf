#!/usr/bin/env bash
# record-demo-cast.sh -- drive the cq-rdf four-subcommand pipe over the
# May 2026 amaru-treasury case study and emit a paced asciinema v2 cast
# at $OUT (default: docs/demo/cast.cast).
#
# This is a regenerator, not a live recorder: each scene executes
# end-to-end against a real Blockfrost endpoint, the actual stdout is
# captured, then the captures are stitched into a deterministically-paced
# cast file so the result is reviewable and reproducible.
#
# Inputs:
#   BLOCKFROST_PROJECT_ID -- Blockfrost mainnet project id. The token
#     value never appears in the output cast; only the literal text
#     '$BLOCKFROST_PROJECT_ID' is rendered.
#   CQRDF -- path to the cq-rdf binary (default: looked up on PATH).
#
# Output:
#   docs/demo/cast.cast -- asciinema v2 JSON, 60-120 s wall-time.
#
# Requirements:
#   - cq-rdf (this repo) on PATH or via $CQRDF
#   - arq (apache-jena) on PATH (in the nix dev shell)
#   - jq, python3
#
# Usage:
#   nix develop -c bash scripts/record-demo-cast.sh
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CASE_DIR="$REPO_ROOT/docs/case-studies/2026-05-amaru-treasury"
OUT="${OUT:-$REPO_ROOT/docs/demo/cast.cast}"

CQRDF_BIN="${CQRDF:-$(command -v cq-rdf || true)}"
if [ -z "$CQRDF_BIN" ]; then
  echo "error: cq-rdf not found on PATH and \$CQRDF unset" >&2
  exit 1
fi
if [ -z "${BLOCKFROST_PROJECT_ID:-}" ]; then
  echo "error: BLOCKFROST_PROJECT_ID not exported" >&2
  exit 1
fi

WORK=$(mktemp -d -t cqrdf-cast-XXXXXX)
trap 'rm -rf "$WORK"' EXIT
cp "$CASE_DIR/overlay.yaml" "$WORK/"
cp "$CASE_DIR/selections.txt" "$WORK/"
cp -r "$CASE_DIR/blueprints" "$WORK/"
cp -r "$CASE_DIR/shapes" "$WORK/"
cp "$REPO_ROOT/docs/demo/queries/contingency-inflow.rq" "$WORK/"

cd "$WORK"

# Scene 1: survey
sc_ls_queries=$(ls blueprints shapes)
sc_overlay_head=$(head -16 overlay.yaml)
sc_selections_wc=$(wc -l selections.txt | awk '{print $1, $2}')

# Scene 3: overlay
"$CQRDF_BIN" overlay --in overlay.yaml > overlay.ttl
sc_overlay_wc=$(wc -l overlay.ttl | awk '{print $1, $2}')
sc_overlay_ttl_head=$(head -10 overlay.ttl)

# Scene 4: body fetch
T0=$(date +%s)
xargs -P8 -n1 "$CQRDF_BIN" body --provider blockfrost \
  --token "$BLOCKFROST_PROJECT_ID" < selections.txt > bodies.ttl 2>/dev/null
T1=$(date +%s)
sc_body_secs=$((T1-T0))
sc_bodies_wc=$(wc -l bodies.ttl | awk '{print $1, $2}')

# Scene 5: blueprint + shacl
cat overlay.ttl bodies.ttl \
  | "$CQRDF_BIN" blueprint --blueprints blueprints/ > package.ttl
"$CQRDF_BIN" shacl --shapes shapes/ < package.ttl > shacl-report.ttl
sc_package_wc=$(wc -l package.ttl | awk '{print $1, $2}')
sc_shacl_lines=$(wc -l < shacl-report.ttl)

# Scene 6: SPARQL
sc_arq_out=$(arq --data package.ttl --query contingency-inflow.rq)

# Scene 7: typed-datum probe
cat > probe.rq <<'EOF'
PREFIX tx: <https://lambdasistemi.github.io/cardano-rdf/fixtures/tx#>
SELECT (COUNT(*) AS ?typed_destinations)
WHERE { ?d tx:OrderDatum_destination ?dst }
EOF
sc_probe_out=$(arq --data package.ttl --query probe.rq)

manifest_dir="$REPO_ROOT/docs/demo"
mkdir -p "$manifest_dir"
manifest="$manifest_dir/.cast-manifest.json"

# jq builds a JSON object with proper escaping so the synthesiser can
# stream the captured outputs without us hand-escaping in shell.
jq -n \
  --arg ls_queries        "$sc_ls_queries" \
  --arg overlay_head      "$sc_overlay_head" \
  --arg selections_wc     "$sc_selections_wc" \
  --arg overlay_wc        "$sc_overlay_wc" \
  --arg overlay_ttl_head  "$sc_overlay_ttl_head" \
  --argjson body_secs     "$sc_body_secs" \
  --arg bodies_wc         "$sc_bodies_wc" \
  --arg package_wc        "$sc_package_wc" \
  --argjson shacl_lines   "$sc_shacl_lines" \
  --arg arq_out           "$sc_arq_out" \
  --arg probe_out         "$sc_probe_out" \
  '{
    ls_queries:        $ls_queries,
    overlay_head:      $overlay_head,
    selections_wc:     $selections_wc,
    overlay_wc:        $overlay_wc,
    overlay_ttl_head:  $overlay_ttl_head,
    body_secs:         $body_secs,
    bodies_wc:         $bodies_wc,
    package_wc:        $package_wc,
    shacl_lines:       $shacl_lines,
    arq_out:           $arq_out,
    probe_out:         $probe_out
  }' > "$manifest"

echo "manifest captured: $manifest" >&2

python3 "$REPO_ROOT/scripts/synth-demo-cast.py" \
  --manifest "$manifest" \
  --out "$OUT"

# Drop the ephemeral manifest -- the cast is the artefact, not the manifest.
rm -f "$manifest"
echo "cast written: $OUT" >&2
