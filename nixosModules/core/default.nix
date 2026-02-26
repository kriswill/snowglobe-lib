# changes / modifications / additions to the core nixos modules provided by nixpkgs
{ lib, ... }:
{
  imports = lib.autoImport ./. { };
}
