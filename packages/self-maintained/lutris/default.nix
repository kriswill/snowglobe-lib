{ pkgs, ... }:
{
  lutris = pkgs.callPackage ./package.nix { };
}
