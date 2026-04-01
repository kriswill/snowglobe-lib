{ pkgs, ... }:
{
  lutris-unwrapped = pkgs.callPackage ./package.nix { };
}
