default:
    just --list

format:
    find . -type f -name '*.hs' -not -path '*/dist-newstyle/*' -exec fourmolu -i {} +
    cabal-fmt -i cardano-rdf.cabal

hlint:
    find . -type f -name '*.hs' -not -path '*/dist-newstyle/*' -exec hlint {} +

build:
    cabal build all -O0

unit match="":
    #!/usr/bin/env bash
    set -euo pipefail
    cabal build exe:tx-graph -O0 >/dev/null
    cabal build exe:tx-view -O0 >/dev/null
    export TX_GRAPH_EXE="$(cabal list-bin exe:tx-graph -O0)"
    export TX_VIEW_EXE="$(cabal list-bin exe:tx-view -O0)"
    if [[ '{{ match }}' == "" ]]; then
        cabal test cardano-rdf:unit-tests -O0 --test-show-details=direct
    else
        cabal test cardano-rdf:unit-tests -O0 \
            --test-show-details=direct \
            --test-option=--match \
            --test-option="{{ match }}"
    fi

smoke-graph:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal build exe:tx-graph -O0 >/dev/null
    "$(cabal list-bin exe:tx-graph -O0)" --help >/dev/null

smoke-view:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal build exe:tx-view -O0 >/dev/null
    "$(cabal list-bin exe:tx-view -O0)" --help >/dev/null

ci:
    just build
    just unit
    just smoke-graph
    just smoke-view
    cabal-fmt -c cardano-rdf.cabal
    find . -type f -name '*.hs' -not -path '*/dist-newstyle/*' -exec fourmolu -m check {} +
    find . -type f -name '*.hs' -not -path '*/dist-newstyle/*' -exec hlint {} +

serve-docs:
    mkdocs serve

build-docs:
    mkdocs build --strict
