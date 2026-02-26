{
  pkgs,
  lib,
  config,
  ...
}:
let
  module-name = "android";
  cfg = config.earthgman.${module-name};
in
{
  options.earthgman.${module-name} = {
    enable = lib.mkEnableOption "EarthGman's ${module-name} configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.kdeconnect = {
      enable = true;
      trayApplet.enable = lib.setDefault true;
    };
  };
  # TODO add more android stuff
}
