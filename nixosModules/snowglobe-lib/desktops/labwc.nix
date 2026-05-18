{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.desktop.labwc;
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.desktop.labwc.enable = lib.mkEnableOption "Snowglobe-Lib's labwc module";

  config = lib.mkIf cfg.enable {
    snowglobe-lib.system.hasDesktop = lib.mkForce true;
    snowglobe-lib.desktop = {
      enable = lib.mkForce true;
      installWaylandDeps = lib.mkForce true;
    };
    programs = {
      labwc = {
        enable = true;
        withUWSM = slib.setDefault true;
      };
      # default terminal
      foot.enable = slib.setDefault true;
      # applications and dmenu
      rofi.enable = slib.setDefault true;
    };
  };
}
