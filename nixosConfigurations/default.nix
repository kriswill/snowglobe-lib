{ lib, ... }:
{
  nixos = lib.mkHost {
    hostname = "nixos";
    cpu-vendor = "amd";
    firmware = "BIOS";
    gpu-vendors = [ ];
    arch = "x86_64-linux";
    desktop = "niri";
    isQemu = true;
    configDir = ./nixos;
  };
}
