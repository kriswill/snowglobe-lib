{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.gman.gpu.nvidia;
in
{
  options.gman.gpu.nvidia.enable = lib.mkEnableOption "gman's nvidia gpu configuration";
  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    programs = {
      sway.extraOptions = [ "--unsupported-gpu" ]; # sway will not launch on nvidia without this set

      btop.package = lib.mkDefault pkgs.btop-cuda;
    };

    hardware.nvidia = {
      modesetting.enable = lib.mkDefault true;

      powerManagement.enable = lib.mkDefault true;

      # use open for RTX 20 series or newer
      open = lib.mkDefault true;
      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = lib.mkDefault true;

      # latest nvidia drivers
      package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.beta;
    };
  };
}
