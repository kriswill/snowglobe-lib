{ inputs, lib, ... }:
let
  sharedModules = [ ../shared ];
in
{
  imports = lib.autoImport ./. ++ [
    inputs.disko.nixosModules.default
    inputs.determinate.nixosModules.default
    inputs.sops-nix.nixosModules.default
  ];
}
