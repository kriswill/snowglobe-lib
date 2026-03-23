{ pkgs, ... }:
let
  inherit (pkgs) callPackage;
in
{
  nixos-grub-theme = callPackage ./nixos-grub-theme { };
  omori-font = callPackage ./omori-font { };
  _8-bit-operator-font = callPackage ./8-bit-operator-font { };
  star-pixel-icons = callPackage ./star-pixel-icons { };
  freetube = callPackage ./self-maintained/freetube { };
  lutris-unwrapped = callPackage ./self-maintained/lutris { };
}
