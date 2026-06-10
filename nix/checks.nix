{ pkgs, src, components, libraryDoc, lintPkgs ? pkgs, pythonEnv, eye, cqRdf, txGraphCompat }:
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

        DOC_HTML="${libraryDoc}/share/doc/cardano-ledger-rdf/html"
        if [ ! -d "$DOC_HTML" ]; then
          echo "✗ haddock html tree missing at $DOC_HTML" >&2
          exit 1
        fi

        expected_modules=(
          Cardano-Tx-Blueprint
          Cardano-Tx-Decode
          Cardano-Tx-Graph-Emit
          Cardano-Tx-Graph-Emit-Blueprint
          Cardano-Tx-Graph-Emit-Project
          Cardano-Tx-Graph-Provider
          Cardano-Tx-Graph-Resolve
          Cardano-Tx-Graph-Resolve-Web2
          Cardano-Tx-Graph-Rules-Load
          Cardano-Tx-Graph-Rules-Load-Imports
          Cardano-Tx-View
        )
        for m in "''${expected_modules[@]}"; do
          if [ ! -f "$DOC_HTML/$m.html" ]; then
            echo "✗ haddock page missing: $m.html" >&2
            exit 1
          fi
        done

        # Doc-string regression guard: the strings below were written
        # by issue #76's slices 1-4 and ANCHOR the documentation
        # surface a Hackage reader sees. A silent deletion of any of
        # them fails this gate.
        declare -a guards=(
          "Cardano-Tx-Blueprint.html:A CIP-0057 Plutus blueprint as parsed from JSON"
          "Cardano-Tx-Blueprint.html:Open, schema-driven projection of a"
          "Cardano-Tx-Decode.html:Decode a bech32-encoded Cardano address"
          "Cardano-Tx-Decode.html:02-alice-bob-ada"
          "Cardano-Tx-Graph-Emit.html:body emitter introduced by"
          "Cardano-Tx-Graph-Emit-Project.html:Render a"
          "Cardano-Tx-Graph-Rules-Load.html:operator-authored rule files"
          "Cardano-Tx-View.html:in-repo view runner. Loads"
        )
        for guard in "''${guards[@]}"; do
          file="''${guard%%:*}"
          needle="''${guard#*:}"
          if ! grep -F -q "$needle" "$DOC_HTML/$file"; then
            echo "✗ regression: '$needle' not found in $file" >&2
            exit 1
          fi
        done

        echo "✓ haddock-coverage gate passed (''${#expected_modules[@]} modules, ''${#guards[@]} regression guards)"
      '';
    };
  };

  gates = lib.mapAttrs (_: mkGate) gateSpecs;
in {
  checks = lib.mapAttrs (_: gate: gate.check) gates;
  scripts = lib.mapAttrs (_: gate: gate.script) gates;
}
