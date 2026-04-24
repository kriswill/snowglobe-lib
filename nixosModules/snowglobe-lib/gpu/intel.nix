{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.snowglobe-lib.gpu.intel;
in
{
  options.snowglobe-lib.gpu.intel.enable = mkEnableOption "Snowglobe-Lib's intel gpu configuration";
  config = mkIf cfg.enable {
    # provide hardware acceleration to most GPUs
    hardware.graphics.extraPackages = builtins.attrValues {
      inherit (pkgs)
        intel-media-driver
        intel-vaapi-driver
        ;
    };
  };
}
