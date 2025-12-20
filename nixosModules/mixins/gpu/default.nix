{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.gpu;
in
{
  imports = lib.autoImport ./.;

  config = lib.mkIf (cfg.amd.enable || cfg.nvidia.enable || cfg.intel.enable) {
    services.lact.enable = lib.mkDefault true;
    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
        # hardware verification tools
        vdpauinfo
        libva-utils
        mesa-demos
        vulkan-tools
        clinfo
        ;
    };
  };
}
