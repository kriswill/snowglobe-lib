{ pkgs, ... }:
{
  snowglobe-rebuild-unwrapped = pkgs.writeScriptBin "snowglobe-rebuild" (
    builtins.readFile ../../lib/scripts/snowglobe-rebuild.sh
  );
  snowglobe-rebuild = pkgs.callPackage ./wrapper.nix { };
}
