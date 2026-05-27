{ pkgs }:

# EYE (Euler Yet another proof Engine) packaged locally so the OWL 2 RL smoke
# can run in the dev shell and in flake checks without a networked runtime.

let
  src = pkgs.fetchFromGitHub {
    owner = "eyereasoner";
    repo = "eye";
    rev = "v11.24.4";
    hash = "sha256-DKpKu1ELN68Wfd6MoAE3nWU414MoukEZRInUQB96sWU=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "eye";
  version = "11.24.4";
  inherit src;

  nativeBuildInputs = [ pkgs.swi-prolog pkgs.makeWrapper ];
  buildInputs = [ pkgs.swi-prolog ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    mkdir -p $out/lib $out/bin
    swipl -q -f ./eye.pl -g main -- --quiet --image $out/lib/eye.pvm
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    substitute eye.sh.in $out/bin/eye --replace-fail '@PREFIX@' "$out"
    chmod 0755 $out/bin/eye
    wrapProgram $out/bin/eye \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.swi-prolog ]}
    mkdir -p $out/share/eye/rpo
    cp reasoning/rpo/*.n3 $out/share/eye/rpo/
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    actual=$($out/bin/eye --version 2>&1)
    case "$actual" in
      *"EYE v11.24.4"*) ;;
      *) echo "eye --version did not report 11.24.4: $actual" >&2; exit 1 ;;
    esac
    runHook postInstallCheck
  '';

  meta = with pkgs.lib; {
    description = "Euler Yet another proof Engine - N3 / OWL 2 RL reasoner";
    homepage = "https://github.com/eyereasoner/eye";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "eye";
  };
}
