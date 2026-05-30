{
  description = "Cardano transaction RDF graph tooling";

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://paolino.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "paolino.cachix.org-1:ecmgO3CXdgSWA2cHlm4srknd/cLFMLmK3i3NrzeDFaE="
    ];
  };

  inputs = {
    haskellNix = {
      url =
        "github:input-output-hk/haskell.nix/8b447d7f57d62fab9249f79bb916bc891e29b9d0";
      inputs.hackage.follows = "hackageNix";
    };
    hackageNix = {
      url = "github:input-output-hk/hackage.nix/b6b4aa4bd699f743238da45c7f43da5a26a822f7";
      flake = false;
    };
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    lintNixpkgs.url =
      "github:NixOS/nixpkgs/647e5c14cbd5067f44ac86b74f014962df460840";
    flake-parts.url = "github:hercules-ci/flake-parts";
    bundlers = {
      url = "github:NixOS/bundlers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dev-assets.url = "github:paolino/dev-assets";
    iohkNix = {
      url =
        "github:input-output-hk/iohk-nix/f444d972c301ddd9f23eac4325ffcc8b5766eee9";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    CHaP = {
      url =
        "github:intersectmbo/cardano-haskell-packages/887d73ce434831e3a67df48e070f4f979b3ac5a6";
      flake = false;
    };
    mkdocs.url = "github:paolino/dev-assets?dir=mkdocs";
  };

  outputs =
    inputs@{ self, nixpkgs, lintNixpkgs, flake-parts, haskellNix, iohkNix
    , CHaP, mkdocs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { system, ... }:
        let
          pkgs = import nixpkgs {
            overlays = [
              iohkNix.overlays.crypto
              haskellNix.overlay
              iohkNix.overlays.haskell-nix-crypto
              iohkNix.overlays.cardano-lib
            ];
            inherit system;
          };
          lib = pkgs.lib;
          lintPkgs = import lintNixpkgs { inherit system; };
          pythonEnv = pkgs.python3.withPackages (ps: [ ps.rdflib ]);
          eye = pkgs.callPackage ./nix/eye.nix { };
          fix-libs = { lib, pkgs, ... }: {
            packages.cardano-crypto-praos.components.library.pkgconfig =
              lib.mkForce [ [ pkgs.libsodium-vrf ] ];
            packages.cardano-crypto-class.components.library.pkgconfig =
              lib.mkForce
                [ [ pkgs.libsodium-vrf pkgs.secp256k1 pkgs.libblst ] ];
            packages.cardano-ledger-binary.components.library.doHaddock =
              lib.mkForce false;
            packages.plutus-core.components.library.doHaddock =
              lib.mkForce false;
            packages.plutus-ledger-api.components.library.doHaddock =
              lib.mkForce false;
            packages.plutus-tx.components.library.doHaddock =
              lib.mkForce false;
          };
          project = pkgs.haskell-nix.cabalProject' {
            name = "cardano-ledger-rdf";
            src = ./.;
            compiler-nix-name = "ghc9123";
            shell = {
              withHoogle = true;
              tools = {
                cabal = { };
              };
              buildInputs = [
                lintPkgs.haskellPackages.cabal-fmt
                lintPkgs.haskellPackages.fourmolu
                lintPkgs.haskellPackages.hlint
                pkgs.just
                pkgs.apache-jena
                pkgs.jre_headless
                pkgs.which
                pkgs.curl
                pkgs.cacert
                pkgs.lmdb
                pkgs.liburing
                pythonEnv
                eye
                mkdocs.packages.${system}.from-nixpkgs
                mkdocs.packages.${system}.asciinema-plugin
              ];
              shellHook = ''
                export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
              '';
            };
            modules = [
              fix-libs
              { packages.cardano-ledger-rdf.flags.werror = true; }
            ];
            inputMap = {
              "https://chap.intersectmbo.org/" = CHaP;
            };
          };
          components = project.hsPkgs.cardano-ledger-rdf.components;
          cqRdfUnwrapped = components.exes.cq-rdf;
          cqRdf = pkgs.runCommand "cq-rdf-${packageVersion}"
            {
              nativeBuildInputs = [ pkgs.makeWrapper ];
              meta.mainProgram = "cq-rdf";
            } ''
            mkdir -p "$out/bin"
            makeWrapper ${cqRdfUnwrapped}/bin/cq-rdf "$out/bin/cq-rdf" \
              --prefix PATH : ${lib.makeBinPath [ pkgs.apache-jena pkgs.jre_headless ]} \
              --set-default SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
          '';
          txGraphCompat = pkgs.runCommand "tx-graph-compat-${packageVersion}"
            { meta.mainProgram = "tx-graph"; } ''
            mkdir -p "$out/bin"
            cat > "$out/bin/tx-graph" <<'EOF'
            #!${pkgs.bash}/bin/bash
            export PATH="${lib.makeBinPath [ pkgs.apache-jena pkgs.jre_headless ]}:$PATH"
            export SSL_CERT_FILE="''${SSL_CERT_FILE:-${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt}"
            exec -a tx-graph ${cqRdfUnwrapped}/bin/cq-rdf "$@"
            EOF
            chmod +x "$out/bin/tx-graph"
          '';
          packageVersion =
            let
              versionLines =
                builtins.filter (lib.hasPrefix "version:")
                  (lib.splitString "\n"
                    (builtins.readFile ./cardano-ledger-rdf.cabal));
            in
            builtins.elemAt
              (builtins.match
                "version:[[:space:]]*([^[:space:]]+)"
                (builtins.head versionLines))
              0;
          sourceRevision =
            self.shortRev or (self.dirtyShortRev or "dirty");
          devArtifactVersion = "${packageVersion}-${sourceRevision}";
          exeSpecs = [
            {
              name = "cq-rdf";
              package = cqRdf;
              desc = "Cardano RDF pipeline primitives";
              formulaClass = "CqRdf";
              formulaTest = ''
                output = shell_output("#{bin}/cq-rdf 2>&1", 0)
                assert_match "Cardano RDF pipeline primitives", output
              '';
              usageGreps = [
                "Usage:"
                "Cardano RDF pipeline primitives"
              ];
            }
            {
              name = "tx-graph";
              package = txGraphCompat;
              desc = "Deprecated compatibility symlink for cq-rdf body";
              formulaClass = "TxGraph";
              formulaTest = ''
                output = shell_output("#{bin}/tx-graph 2>&1", 0)
                assert_match "--rules", output
              '';
              usageGreps = [
                "Usage:"
                "--rules"
              ];
            }
            {
              name = "tx-view";
              package = components.exes.tx-view;
              desc =
                "Project canonical Turtle graphs through packaged SPARQL views";
              formulaClass = "TxView";
              smokeExitCode = 1;
              formulaTest = ''
                output = shell_output("#{bin}/tx-view 2>&1", 1)
                assert_match "canonical Turtle graph file", output
              '';
              usageGreps = [
                "Usage:"
                "canonical Turtle graph file"
              ];
            }
          ];
          mkExeSmokeCommand = spec:
            ''
              set +e
              ${spec.name} >/tmp/${spec.name}.out 2>&1
              status="$?"
              set -e
              test "$status" -eq ${toString (spec.smokeExitCode or 0)}
            ''
            + lib.concatMapStringsSep "\n"
              (g: "  grep -F -- ${lib.escapeShellArg g} /tmp/${spec.name}.out >/dev/null")
              spec.usageGreps;
          mkDarwinHomebrewBundle =
            inputs.dev-assets.lib.mkDarwinHomebrewBundle { inherit pkgs; };
          darwinPackageOf = spec: spec.darwinPackage or spec.package;
          mkExeDarwinHomebrewBundle = spec: args:
            mkDarwinHomebrewBundle ({
              pname = spec.name;
              version = packageVersion;
              owner = "lambdasistemi";
              repo = "cardano-ledger-rdf";
              desc = spec.desc;
              formulaClass = spec.formulaClass;
              executables = { ${spec.name} = darwinPackageOf spec; };
              executableNames = [ spec.name ];
              formulaTest = spec.formulaTest;
              smokeCommands = [ (mkExeSmokeCommand spec) ];
            } // args);
          mkExeLinuxRelease = spec: extraArgs:
            import ./nix/linux-release.nix ({
              inherit pkgs system packageVersion;
              executableName = spec.name;
              package = spec.package;
              bundlers = inputs.bundlers;
            } // extraArgs);
          darwinReleasePackages = lib.optionalAttrs
            pkgs.stdenv.isDarwin
            (lib.listToAttrs
              (lib.concatMap (spec: [
                {
                  name = "${spec.name}-darwin-release-artifacts";
                  value = mkExeDarwinHomebrewBundle spec { };
                }
                {
                  name = "${spec.name}-darwin-dev-homebrew-artifacts";
                  value = mkExeDarwinHomebrewBundle spec {
                    artifactVersion = devArtifactVersion;
                    releaseTag = "dev-homebrew-${spec.name}";
                    formulaName = "${spec.name}-dev";
                    formulaClass = "${spec.formulaClass}Dev";
                    formulaVersion = devArtifactVersion;
                  };
                }
              ]) exeSpecs));
          linuxReleasePackages = lib.optionalAttrs
            pkgs.stdenv.isLinux
            (lib.listToAttrs
              (lib.concatMap (spec: [
                {
                  name = "${spec.name}-linux-release-artifacts";
                  value = mkExeLinuxRelease spec { };
                }
                {
                  name = "${spec.name}-linux-dev-release-artifacts";
                  value = mkExeLinuxRelease spec {
                    artifactVersion = devArtifactVersion;
                  };
                }
              ]) exeSpecs)
            // {
              linux-artifact-smoke =
                import ./nix/linux-artifact-smoke.nix {
                  inherit pkgs system;
                };
            });
          checkSuite = import ./nix/checks.nix {
            inherit pkgs components lintPkgs pythonEnv eye cqRdf txGraphCompat;
            src = ./.;
          };
          checkApps = import ./nix/apps.nix {
            inherit pkgs;
            inherit (checkSuite) scripts;
          };
          unitWithTxView = pkgs.writeShellApplication {
            name = "unit-with-tx-view";
            runtimeInputs = [ checkSuite.scripts.unit ];
            text = ''
              export TX_VIEW_EXE=${components.exes.tx-view}/bin/tx-view
              export CQ_RDF_EXE=${cqRdf}/bin/cq-rdf
              export TX_GRAPH_EXE=${txGraphCompat}/bin/tx-graph
              exec ${lib.getExe checkSuite.scripts.unit} "$@"
            '';
          };
        in {
          packages = {
            default = cqRdf;
            cq-rdf = cqRdf;
            tx-graph = txGraphCompat;
            tx-view = components.exes.tx-view;
          } // darwinReleasePackages // linuxReleasePackages;
          checks = checkSuite.checks // {
            unit = pkgs.runCommand "unit-check"
              {
                nativeBuildInputs =
                  lib.optionals pkgs.stdenv.hostPlatform.isLinux
                    [ pkgs.glibcLocales ];
                LANG = "C.UTF-8";
                LC_ALL = "C.UTF-8";
              } ''
                set -euo pipefail
                cd ${./.}
                export TX_VIEW_EXE=${components.exes.tx-view}/bin/tx-view
                ${lib.getExe checkSuite.scripts.unit}
                touch "$out"
              '';
          };
          apps = checkApps // {
            unit = {
              type = "app";
              program = "${unitWithTxView}/bin/unit-with-tx-view";
            };
            tx-graph = {
              type = "app";
              program = "${txGraphCompat}/bin/tx-graph";
            };
            cq-rdf = {
              type = "app";
              program = "${cqRdf}/bin/cq-rdf";
            };
            tx-view = {
              type = "app";
              program = "${components.exes.tx-view}/bin/tx-view";
            };
          } // lib.optionalAttrs pkgs.stdenv.isLinux {
            linux-artifact-smoke = {
              type = "app";
              program =
                "${linuxReleasePackages.linux-artifact-smoke}/bin/linux-artifact-smoke";
            };
          };
          devShells.default = project.shell;
        };
    };
}
