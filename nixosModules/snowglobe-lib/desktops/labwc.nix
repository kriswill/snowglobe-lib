{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-lib.desktop.labwc;
in
{
  options.snowglobe-lib.desktop.labwc.enable = lib.mkEnableOption "Snowglobe-Lib's labwc module";

  config = lib.mkIf cfg.enable {
    snowglobe-lib.desktop.enable = true;
    programs.labwc.enable = true;
  };
}
