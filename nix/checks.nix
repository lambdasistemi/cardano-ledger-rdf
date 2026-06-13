{ pkgs
, src
, components
, libraryDoc
, coreLibraryDoc
, lintPkgs ? pkgs
, pythonEnv
, eye
, cqRdf
, txGraphCompat
}:
let
  lib = pkgs.lib;

  mkCheck = name: script:
    pkgs.runCommand "${name}-check" {
      nativeBuildInputs =
        lib.optionals pkgs.stdenv.hostPlatform.isLinux
          [ pkgs.glibcLocales ];
      LANG = "C.UTF-8";
      LC_ALL = "C.UTF-8";
    } ''
      set -euo pipefail
      cd ${src}
      ${lib.getExe script}
      touch "$out"
    '';

  mkScript = { name, runtimeInputs ? [ ], text }:
    pkgs.writeShellApplication {
      inherit name runtimeInputs text;
    };

  mkGate = spec:
    let
      script = mkScript spec;
    in {
      check = mkCheck spec.name script;
      inherit script;
    };

  lintInputs = [
    lintPkgs.haskellPackages.cabal-fmt
    lintPkgs.haskellPackages.fourmolu
    lintPkgs.haskellPackages.hlint
    pkgs.bash
    pkgs.findutils
    pkgs.gawk
    pkgs.gnugrep
  ];

  gateSpecs = {
    build = {
      name = "build";
      text = ''
        test -e ${components.library}
        test -e ${cqRdf}
        test -e ${txGraphCompat}
        test -e ${components.exes.tx-view}
        test -e ${components.tests."unit-tests"}
        echo "build outputs realized"
      '';
    };

    unit = {
      name = "unit";
      runtimeInputs = [
        components.tests.unit-tests
        pkgs.apache-jena
        pkgs.jre_headless
        pkgs.which
      ];
      # Exe specs spawn cq-rdf and the deprecated tx-graph symlink
      # as subprocesses. The nix-check sandbox has no cabal on PATH,
      # so we set both env vars to haskell.nix store paths.
      text = ''
        export CQ_RDF_EXE=${cqRdf}/bin/cq-rdf
        export TX_GRAPH_EXE=${txGraphCompat}/bin/tx-graph
        unit-tests
      '';
    };

    lint = {
      name = "lint";
      runtimeInputs = lintInputs;
      text = ''
        cd ${src}
        cabal-fmt -c cardano-ledger-rdf.cabal
        find . -type f -name '*.hs' \
          -not -path '*/dist-newstyle/*' \
          -exec fourmolu -m check {} +
        find . -type f -name '*.hs' \
          -not -path '*/dist-newstyle/*' \
          -exec hlint {} +
      '';
    };

    vocab-validate = {
      name = "vocab-validate";
      runtimeInputs = [ pythonEnv ];
      text = ''
        cd ${src}
        python3 scripts/validate-ttl.py
      '';
    };

    vocab-owl-smoke = {
      name = "vocab-owl-smoke";
      runtimeInputs = [ pythonEnv eye ];
      text = ''
        cd ${src}
        python3 scripts/owl-smoke.py
      '';
    };

    vocab-accessibility = {
      name = "vocab-accessibility";
      runtimeInputs = [ pythonEnv ];
      text = ''
        cd ${src}
        python3 scripts/vocab-accessibility.py
      '';
    };

    haddock-coverage = {
      name = "haddock-coverage";
      runtimeInputs = [ pkgs.gnugrep pkgs.findutils pkgs.coreutils ];
      # The library.doc derivation only realises when haskell.nix's
      # haddock build for `cardano-ledger-rdf` succeeds — which in turn
      # only happens when every locally-defined export has a parseable
      # Haddock attachment. The check below verifies (a) the HTML tree
      # is present, (b) every locally-defined module has a rendered
      # page, and (c) a small set of high-value doc strings written by
      # issue #76 has survived in the rendered output.
      #
      # The transaction-builder modules (Cardano.Tx.Build and friends)
      # no longer live here — issue #86 deleted the local copy in favour
      # of cardano-tx-tools:tx-build — so they are absent from both the
      # expected-page list and the doc-string guards below.
      text = ''
        set -euo pipefail

        FAT_DOC_HTML="${libraryDoc}/share/doc/cardano-ledger-rdf/html"
        CORE_DOC_HTML="${coreLibraryDoc}/share/doc/tx-rdf-core/html"
        for doc_html in "$FAT_DOC_HTML" "$CORE_DOC_HTML"; do
          if [ ! -d "$doc_html" ]; then
            echo "✗ haddock html tree missing at $doc_html" >&2
            exit 1
          fi
        done

        check_page() {
          doc_html="$1"
          module_page="$2"
          if [ ! -f "$doc_html/$module_page.html" ]; then
            echo "✗ haddock page missing: $module_page.html in $doc_html" >&2
            exit 1
          fi
        }

        check_guard() {
          doc_html="$1"
          guard="$2"
          file="''${guard%%:*}"
          needle="''${guard#*:}"
          if ! grep -F -q "$needle" "$doc_html/$file"; then
            echo "✗ regression: '$needle' not found in $doc_html/$file" >&2
            exit 1
          fi
        }

        core_expected_modules=(
          Cardano-Tx-Blueprint
          Cardano-Tx-Decode
          Cardano-Tx-Graph-Emit
          Cardano-Tx-Graph-Emit-Blueprint
          Cardano-Tx-Graph-Emit-Project
          Cardano-Tx-Graph-Rules-Load-Imports
          Cardano-Tx-View
        )
        for m in "''${core_expected_modules[@]}"; do
          check_page "$CORE_DOC_HTML" "$m"
        done

        fat_expected_modules=(
          Cardano-Tx-Graph-Provider
          Cardano-Tx-Graph-Resolve
          Cardano-Tx-Graph-Resolve-Web2
          Cardano-Tx-Graph-Rules-Load
        )
        for m in "''${fat_expected_modules[@]}"; do
          check_page "$FAT_DOC_HTML" "$m"
        done

        # Doc-string regression guard: the strings below were written
        # by issue #76's slices 1-4 and ANCHOR the documentation
        # surface a Hackage reader sees. A silent deletion of any of
        # them fails this gate.
        declare -a core_guards=(
          "Cardano-Tx-Blueprint.html:A CIP-0057 Plutus blueprint as parsed from JSON"
          "Cardano-Tx-Blueprint.html:Open, schema-driven projection of a"
          "Cardano-Tx-Decode.html:Decode a bech32-encoded Cardano address"
          "Cardano-Tx-Decode.html:02-alice-bob-ada"
          "Cardano-Tx-Graph-Emit.html:body emitter introduced by"
          "Cardano-Tx-Graph-Emit-Project.html:Render a"
          "Cardano-Tx-View.html:in-repo view runner. Loads"
        )
        for guard in "''${core_guards[@]}"; do
          check_guard "$CORE_DOC_HTML" "$guard"
        done

        declare -a fat_guards=(
          "Cardano-Tx-Graph-Rules-Load.html:operator-authored rule files"
        )
        for guard in "''${fat_guards[@]}"; do
          check_guard "$FAT_DOC_HTML" "$guard"
        done

        expected_count=$((
          ''${#core_expected_modules[@]} + ''${#fat_expected_modules[@]}
        ))
        guard_count=$((
          ''${#core_guards[@]} + ''${#fat_guards[@]}
        ))

        echo "✓ haddock-coverage gate passed ($expected_count modules, $guard_count regression guards)"
      '';
    };
  };

  gates = lib.mapAttrs (_: mkGate) gateSpecs;
in {
  checks = lib.mapAttrs (_: gate: gate.check) gates;
  scripts = lib.mapAttrs (_: gate: gate.script) gates;
}
