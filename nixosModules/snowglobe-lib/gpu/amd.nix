{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../lib/functions/module-wrappers { inherit lib; };
  cfg = config.snowglobe-lib.gpu.amd;
in
{
  options.snowglobe-lib.gpu.amd.enable = lib.mkEnableOption "Snowglobe-Lib's amdgpu configuration";
  config = lib.mkIf cfg.enable {
    services = {
      xserver.videoDrivers = [ "amdgpu" ];
    };

    # provide special derivation that can monitor amdgpu stats
    programs.btop.package = slib.setDefault pkgs.btop-rocm;

    hardware = {
      # allow overclocking
      amdgpu.overdrive.enable = slib.setDefault true;
      # enable full resolution during early KMS while booting
      amdgpu.initrd.enable = lib.mkDefault true;
    };
  };
}
