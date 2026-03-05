{ lib, ... }:
{
  nixos-installer-x86_64 = lib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configuration = ./nixos-installer/configuration.nix;
  };
}
