{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.desktop.hyprland;
in
{
  options.gman.desktop.hyprland.enable = lib.mkEnableOption "hyprland with uwsm";

  config = lib.mkIf cfg.enable {
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
      };
      hyprlock.enable = true;
      rofi.enable = lib.mkDefault true;
      kitty.enable = lib.mkDefault true;
      waybar.enable = lib.mkDefault true;
    };

    security.hyprpolkitagent.enable = true;

    services = {
      # notification daemon
      swaync.enable = true;

      hypridle.enable = true;
    };

    xdg.portal = {
      wlr.enable = true;
      config.hyprland = {
        default = [
          "wlr"
          "hyprland"
          "gtk"
        ];
      };
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        libnotify
        wl-clipboard
        grim
        slurp
        # screenshot script
        grimblast
        # graphical prompt for sudo / other polkit rules
        hyprpolkitagent
        ;
    };
  };
}
