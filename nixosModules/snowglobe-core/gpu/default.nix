{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.gpu;
  moduleEnabled = (cfg.amd.enable || cfg.nvidia.enable || cfg.intel.enable);
in
{
  imports = lib.autoImport ./. { };

  config = lib.mkIf moduleEnabled {
    hardware.graphics.enable = true;
    # good tool for monitoring and control of your gpu
    services.lact.enable = lib.setDefault true;
  };
}
