# triggered by the gaming specialization from the installer
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.profiles.gaming;
in
{
  options.snowglobe-core.profiles.gaming = {
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

        programs = {
          # open source frontend for managing your games and emulators
          lutris.enable = lib.setDefault true;

          # performance overlay
          mangohud.enable = lib.setDefault true;

          # install proton versions
          protonup-qt.enable = lib.setDefault true;

          # autoclicker (this works in wayland as most games run in xwayland)
          xclicker.enable = lib.setDefault true;

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
