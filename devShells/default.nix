{ pkgs }:
let
  ci-sh = pkgs.writeScriptBin "ci.sh" (builtins.readFile ../lib/scripts/ci.sh);
  nixfmt-sh = pkgs.writeScriptBin "nixfmt.sh" (builtins.readFile ../lib/scripts/nixfmt.sh);
  build-installers-sh = pkgs.writeScriptBin "build-installers.sh" (
    builtins.readFile ../lib/scripts/build-installers.sh
  );
in
pkgs.mkShell {
  packages = [
    ci-sh
    nixfmt-sh
    build-installers-sh
  ];

  shellHook = ''
    export PROJECT_ROOT="$HOME/src/git/earthgman.dev/earthgman/nix-modules"
  '';
}
