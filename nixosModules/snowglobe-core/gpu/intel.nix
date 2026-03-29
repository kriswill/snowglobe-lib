{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.snowglobe-core.gpu.intel;
in
{
  options.snowglobe-core.gpu.intel.enable = mkEnableOption "Snowglobe-Core's intel gpu configuration";
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
