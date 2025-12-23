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

  nixos-installer-aarch64 = lib.mkHost {
    hostname = "nixos-installer";
    system = "aarch64-linux";
    configDir = ./nixos-installer;
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
