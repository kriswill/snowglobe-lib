{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.snowglobe-core.gpu.amd;
in
{
  options.snowglobe-core.gpu.amd.enable = lib.mkEnableOption "Snowglobe-Core's amdgpu configuration";
  config = lib.mkIf cfg.enable {
    services = {
      xserver.videoDrivers = [ "amdgpu" ];
    };

    # provide special derivation that can monitor amdgpu stats
    programs.btop.package = lib.setDefault pkgs.btop-rocm;

    hardware = {
      # allow overclocking
      amdgpu.overdrive.enable = lib.setDefault true;
      # enable full resolution during early KMS while booting
      amdgpu.initrd.enable = lib.mkDefault true;
    };
  };
}
