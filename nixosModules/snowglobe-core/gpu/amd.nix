{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.gpu.amd;
in
{
  options.earthgman.gpu.amd.enable = lib.mkEnableOption "EarthGman's amdgpu configuration";
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
