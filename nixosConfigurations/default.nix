{ lib, ... }:
{
  nixos-installer-x86_64 = lib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configuration = ./nixos-installer/configuration.nix;
  };

  nixos = lib.mkNixosHost {
    hostname = "nixos";
    cpu-vendor = "amd";
    firmware = "BIOS";
    gpu-vendors = [ ];
    system = "x86_64-linux";
    desktop = "niri";
    isQemu = true;
    configuration = ./nixos/configuration.nix;
    sopsFile = null;
  };
}
