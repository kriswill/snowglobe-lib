{
  outputs,
  lib,
  slib,
  ...
}:
{
  snowglobe-installer-x86_64 = slib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./snowglobe-installer;
  };

  snowglobe-installer-x86_64-small = slib.mkNixosHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./snowglobe-installer;
    modules = [
      { hardware.enableRedistributableFirmware = lib.mkForce false; }
    ];
  };
}
