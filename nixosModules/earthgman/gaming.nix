# triggered by the gaming specialization from the installer
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.gaming;
in
{
  options.earthgman.gaming = {
    enable = lib.mkEnableOption "utilities for that OOB Linux gaming experience";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment = {
          systemPackages = [
            pkgs.protonup-ng
          ];
        };

        hardware = {
          xone.enable = lib.setDefault true;
        };

        earthgman = {
          # do some hardware benchmarking
          hardware-tools.enable = lib.setDefault true;
        };

        programs = {
          # emulators
          dolphin-emu.enable = lib.setDefault true;
          cemu.enable = lib.setDefault true;
          ryubing.enable = lib.setDefault true;

          # open source frontend for managing your games
          lutris.enable = lib.setDefault true;

          # performance overlay
          mangohud.enable = lib.setDefault true;

          # install proton versions
          protonup-qt.enable = lib.setDefault true;

          # proprietary garbage, but required :(
          steam = {
            enable = true;
            gamescopeSession = {
              enable = lib.setDefault true;
            };
            localNetworkGameTransfers.openFirewall = lib.setDefault true;
          };
        };
        # TODO gamemode
      }
    ]
  );
}
