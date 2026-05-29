{ pkgs, src, components, lintPkgs ? pkgs, pythonEnv, eye }:
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
        test -e ${components.exes.tx-graph}
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
      # LoadExeSpec spawns the tx-graph binary as a subprocess and
      # reads its path from TX_GRAPH_EXE (with a `cabal list-bin`
      # fallback for the dev shell). The nix-check sandbox has no
      # cabal on PATH, so we set the env var to the haskell.nix
      # store path here — the same way components.tests.unit-tests
      # is wired in as a runtimeInput.
      text = ''
        export TX_GRAPH_EXE=${components.exes.tx-graph}/bin/tx-graph
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
  };

  gates = lib.mapAttrs (_: mkGate) gateSpecs;
in {
  checks = lib.mapAttrs (_: gate: gate.check) gates;
  scripts = lib.mapAttrs (_: gate: gate.script) gates;
}
