{ pkgs }:
let
  ci-sh = pkgs.writeScriptBin "ci.sh" (builtins.readFile ../scripts/ci.sh);
  nixfmt-sh = pkgs.writeScriptBin "nixfmt.sh" (builtins.readFile ../scripts/nixfmt.sh);
  build-installers-sh = pkgs.writeScriptBin "build-installers.sh" (
    builtins.readFile ../scripts/build-installers.sh
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
