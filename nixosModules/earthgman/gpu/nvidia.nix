{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.earthgman.gpu.nvidia;
in
{
  options.earthgman.gpu.nvidia = {
    enable = lib.mkEnableOption "EarthGman's nvidia gpu configuration";
  };
  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    programs = {
      #   sway.extraOptions = [ "--unsupported-gpu" ]; # sway will not launch on nvidia without this set
      # allow monitoring output through btop
      btop.package = lib.setDefault pkgs.btop-cuda;
    };

    hardware.nvidia = {
      modesetting.enable = lib.setDefault true;

      powerManagement.enable = lib.setDefault true;

      # use open for RTX 20 series or newer
      # TODO some way to detect old cards which this does not work
      open = lib.setDefault true;
      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = lib.mkIf (config.system.desktop != null) lib.setDefault true;

      # latest nvidia drivers
      # nvidia loves dropping support for old cards, a manual override might be required
      package = lib.setDefault config.boot.kernelPackages.nvidiaPackages.beta;
    };
  };
}
