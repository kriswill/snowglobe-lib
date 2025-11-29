{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.gpu.amd;
in
{
  options.gman.gpu.amd.enable = lib.mkEnableOption "gman's amdgpu configuration";
  config = lib.mkIf cfg.enable {
    services = {
      xserver.videoDrivers = [ "amdgpu" ];
      lact.enable = lib.mkDefault true;
    };

    # provide special derivation that can monitor amdgpu stats
    programs.btop.package = lib.mkDefault pkgs.btop-rocm;

    hardware = {
      amdgpu.overdrive.enable = lib.mkDefault true;
    };
  };
}
