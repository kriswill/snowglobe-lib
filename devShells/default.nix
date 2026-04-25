{ pkgs }:
let
  ci-sh = pkgs.writeScriptBin "ci.sh" (builtins.readFile ../lib/scripts/ci.sh);
  build-installers-sh = pkgs.writeScriptBin "build-installers.sh" (
    builtins.readFile ../lib/scripts/build-installers.sh
  );
in
pkgs.mkShell {
  packages = [
    ci-sh
    build-installers-sh
  ];
}
