{ pkgs, inputs, ... }:
let
  inherit (pkgs) callPackage;
in
{
  nixos-grub = callPackage ./grub-themes/nixos.nix { };
  omori-font = callPackage ./fonts/omori-font.nix { inherit inputs; };
  _8-bit-operator-font = callPackage ./fonts/8-bit-operator-font.nix { inherit inputs; };
  mov-cli-youtube = callPackage ./mov-cli-plugins/youtube.nix { };
  star-pixel-icons = callPackage ./icons/star-pixel-icons.nix { };
  # wireguird = callPackage ./wireguird/package.nix { };
}
