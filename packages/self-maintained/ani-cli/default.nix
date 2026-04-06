{ pkgs, ... }:
{
  ani-cli = pkgs.callPackage ./package.nix { };
}
