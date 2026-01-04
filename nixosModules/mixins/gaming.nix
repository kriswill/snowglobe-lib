# triggered by the gaming specialization from the installer
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.gaming;
in
{
  options.gman.gaming = {
    enable = lib.mkEnableOption "Various out of the box utilities for the 'gaming' specialization";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment = {
          systemPackages = [
            pkgs.protonup-ng
          ];
          # sessionVariables = {
          #   STEAM_EXTRA_COMPAT_TOOLS_PATHS = "~/.steam/root/compatibilitytools.d";
          # };
        };

        hardware = {
          xone.enable = lib.mkDefault true;
        };

        gman = {
          hardware-tools.enable = lib.mkDefault true;
        };

        programs = {
          steam-rom-manager.enable = lib.mkDefault true;
          lutris.enable = lib.mkDefault true;
          mangohud.enable = lib.mkDefault true;
          protonup.enable = lib.mkDefault true;
          steam = {
            enable = true;
            gamescopeSession = {
              enable = lib.mkDefault true;
            };
            localNetworkGameTransfers.openFirewall = lib.mkDefault true;
          };
        };
        # TODO gamemode
      }
    ]
  );
}
