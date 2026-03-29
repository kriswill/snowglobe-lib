{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.earthgman.gpu.intel;
in
{
  options.earthgman.gpu.intel.enable = mkEnableOption "EarthGman's intel gpu configuration";
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
