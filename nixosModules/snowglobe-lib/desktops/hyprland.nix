{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.desktop.hyprland;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.desktop.hyprland.enable =
    lib.mkEnableOption "Snowglobe-lib's default hyprland configuration";

  config = lib.mkIf cfg.enable {
    snowglobe-lib = {
      system.hasDesktop = lib.mkForce true;
      desktop = {
        enable = true;
        installWaylandDeps = true;
      };
    };

    # install programs for hyprland's default config
    programs = {
      hyprland = {
        enable = true;
        # use uwsm to start graphical-session.target by default
        withUWSM = slib.setDefault true;
      };
      # default terminal
      kitty.enable = slib.setDefault true;
      # default filemanager
      dolphin.enable = slib.setDefault true;
      # default menu
      hyprlauncher.enable = slib.setDefault true;
    };
  };
}
