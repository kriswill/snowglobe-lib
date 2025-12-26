{
  inputs,
  lib,
  ...
}:
{
  # custom installer
  nixos-installer-x86_64 = lib.mkHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./nixos-installer;
  };

  nixos-installer-x86_64-small = lib.mkHost {
    hostname = "nixos-installer";
    system = "x86_64-linux";
    configDir = ./nixos-installer;
    # disable linux firmware as its extremely fat and not needed all of the time, especially for VMs
    extraModules = [ { hardware.enableRedistributableFirmware = lib.mkForce false; } ];
  };

  nixos-installer-aarch64 = lib.mkHost {
    hostname = "nixos-installer";
    system = "aarch64-linux";
    configDir = ./nixos-installer;
  };

  nixos-installer-aarch64-small = lib.mkHost {
    hostname = "nixos-installer";
    system = "aarch64-linux";
    configDir = ./nixos-installer;
    # disable linux firmware as its extremely fat and not needed all of the time, especially for VMs
    extraModules = [ { hardware.enableRedistributableFirmware = lib.mkForce false; } ];
  };

  # test vm for install.sh and other
  nixos = lib.mkHost {
    hostname = "nixos";
    bios = "legacy";
    vm = true;
    desktop = "plasma";
    configDir = ./nixos;
    stateVersion = "25.11";
    system = "x86_64-linux";
  };
}
