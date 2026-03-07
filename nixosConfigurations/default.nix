{ lib, ... }:
{
  nixos-installer-x86_64 = lib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./nixos-installer;
  };

  nixos-installer-x86_64-small = lib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./nixos-installer;
    modules = [
      { hardware.enableRedistributableFirmware = lib.mkForce false; }
    ];
  };
}
