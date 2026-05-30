default:
    just --list

format:
    find . -type f -name '*.hs' -not -path '*/dist-newstyle/*' -exec fourmolu -i {} +
    cabal-fmt -i cardano-ledger-rdf.cabal

hlint:
    find . -type f -name '*.hs' -not -path '*/dist-newstyle/*' -exec hlint {} +

build:
    cabal build all -O0

unit match="":
    #!/usr/bin/env bash
    set -euo pipefail
    cabal build exe:cq-rdf -O0 >/dev/null
    cabal build exe:tx-view -O0 >/dev/null
    cq_rdf="$(cabal list-bin exe:cq-rdf -O0)"
    tx_graph_link="$(mktemp -d)/tx-graph"
    ln -s "$cq_rdf" "$tx_graph_link"
    export CQ_RDF_EXE="$cq_rdf"
    export TX_GRAPH_EXE="$tx_graph_link"
    export TX_VIEW_EXE="$(cabal list-bin exe:tx-view -O0)"
    if [[ '{{ match }}' == "" ]]; then
        cabal test cardano-ledger-rdf:unit-tests -O0 --test-show-details=direct
    else
        cabal test cardano-ledger-rdf:unit-tests -O0 \
            --test-show-details=direct \
            --test-option=--match \
            --test-option="{{ match }}"
    fi

smoke-graph:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal build exe:cq-rdf -O0 >/dev/null
    "$(cabal list-bin exe:cq-rdf -O0)" --help >/dev/null

smoke-view:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal build exe:tx-view -O0 >/dev/null
    "$(cabal list-bin exe:tx-view -O0)" --help >/dev/null

vocab-validate:
    python3 scripts/validate-ttl.py

vocab-owl-smoke:
    python3 scripts/owl-smoke.py

vocab-accessibility:
    python3 scripts/vocab-accessibility.py
    python3 scripts/vocab-accessibility.py --self-test

ci:
    just build
    just unit
    just smoke-graph
    just smoke-view
    just vocab-validate
    just vocab-owl-smoke
    just vocab-accessibility
    cabal-fmt -c cardano-ledger-rdf.cabal
    find . -type f -name '*.hs' -not -path '*/dist-newstyle/*' -exec fourmolu -m check {} +
    find . -type f -name '*.hs' -not -path '*/dist-newstyle/*' -exec hlint {} +

serve-docs:
    mkdocs serve

build-docs:
    mkdocs build --strict
