{ flake, pkgs }:
let
  snowglobe-rebuild = flake.outputs.packages.${pkgs.stdenv.hostPlatform.system}.snowglobe-rebuild;
  ci-sh = pkgs.writeScriptBin "ci.sh" (builtins.readFile ./lib/scripts/ci.sh);
in
{
  default = pkgs.mkShell {
    packages = [
      ci-sh
      snowglobe-rebuild
    ];
  };
}
