{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.gman.gpu.intel;
in
{
  options.gman.gpu.intel.enable = mkEnableOption "gman's intel gpu module";
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
