{ pkgs, flake }:
let
  inherit (pkgs) callPackage;
in
{
  snowglobe-rebuild = callPackage ./snowglobe-rebuild { inherit flake; };
  omori-font = callPackage ./omori-font { };
  _8-bit-operator-font = callPackage ./8-bit-operator-font { };
  star-pixel-icons = callPackage ./star-pixel-icons { };
  # corekeeper-dedicated-server = callPackage ./steamServers/corekeeper.nix { };
  helium = callPackage ./helium { };
}
