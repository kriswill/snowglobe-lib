{ pkgs, ... }:
let
  inherit (pkgs) callPackage;
in
{
  nixos-grub-theme = callPackage ./nixos-grub-theme { };
  # omori-font = callPackage ./omori-font { };
  # _8-bit-operator-font = callPackage ./8-bit-operator-font { };
  star-pixel-icons = callPackage ./star-pixel-icons { };
  steamServers = import ./steamServers { inherit pkgs; };
}
// import ./snowglobe-rebuild { inherit pkgs; }
