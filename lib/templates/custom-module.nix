{
  pkgs,
  lib,
  config,
  ...
}:
let
  module-name = "";
  cfg = config.earthgman.${module-name};
in
{
  options.earthgman.${module-name} = {
    enable = lib.mkEnableOption "EarthGman's ${module-name} configuration";
  };

  config = lib.mkIf cfg.enable {

  };
}
