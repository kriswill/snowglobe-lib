{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.steam;
in
{
  options.gman.steam.enable = lib.mkEnableOption "gman's steam configuration";
  config = lib.mkIf cfg.enable {
    programs = {
      mangohud.enable = lib.mkDefault true;
      protonup.enable = lib.mkDefault true;
      steam = {
        enable = true;
        gamescopeSession = {
          enable = lib.mkDefault true;
        };
      };
    };
    environment = {
      systemPackages = [
        pkgs.protonup-ng
      ];
      # sessionVariables = {
      #   STEAM_EXTRA_COMPAT_TOOLS_PATHS = "~/.steam/root/compatibilitytools.d";
      # };
    };
  };
}
