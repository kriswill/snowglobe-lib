{ lib, pkgs, ... }:
let
  packages = lib.filter (name: name != "default.nix") (builtins.attrNames (builtins.readDir ./.));
  importPackages =
    packages: numPackages:
    let
      package = builtins.elemAt packages (numPackages - 1);
    in
    if (numPackages == 1) then
      (import ./${package} { inherit pkgs; })
    else
      (import ./${package} { inherit pkgs; } // (importPackages packages (numPackages - 1)));
in
importPackages packages (builtins.length packages)
