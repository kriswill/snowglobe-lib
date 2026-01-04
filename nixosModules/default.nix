{ inputs, lib, ... }:
{
  imports = [
    ./core
    ./mixins
    inputs.disko.nixosModules.default
    inputs.determinate.nixosModules.default
    inputs.sops-nix.nixosModules.default
  ];
}
