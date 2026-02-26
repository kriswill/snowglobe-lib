{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = lib.autoImport ./users { } ++ [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./programs.nix
  ];

  # earthgman.enable = false;
  earthgman.developer-tools.enable = true;
  earthgman.harden.enable = true;
  earthgman.display-manager.display-manager = "sddm";
  earthgman.dotfile-deps.enable = true;
}
