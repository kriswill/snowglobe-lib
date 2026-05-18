{ pkgs }:
let
  ci-sh = pkgs.writeScriptBin "ci.sh" (builtins.readFile ../lib/scripts/ci.sh);
in
pkgs.mkShell {
  packages = [
    ci-sh
  ];
}
