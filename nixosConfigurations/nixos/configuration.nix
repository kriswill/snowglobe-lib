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

  earthgman.development-tools.enable = true;
  earthgman.harden.enable = true;
  earthgman.dotfile-deps.enable = true;
}
