{ lib, ... }:
{
  snowglobe-installer-x86_64 = lib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./snowglobe-installer;
  };

  snowglobe-installer-x86_64-small = lib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./snowglobe-installer;
    modules = [
      { hardware.enableRedistributableFirmware = lib.mkForce false; }
    ];
  };
}
