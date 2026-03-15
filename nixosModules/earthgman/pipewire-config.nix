{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.earthgman.pipewire-config;
in
{
  options.earthgman.pipewire-config.enable = lib.mkEnableOption "EarthGman's pipewire configuration";
  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true; # hands out realtime scheduling priority to user processes on demand. Improves performance of pulse

    services = {
      pipewire = {
        # enables alsa, pulseaudio, and jack support by default
        enable = lib.mkDefault true;
        alsa.enable = lib.mkDefault true;
        alsa.support32Bit = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
        jack.enable = lib.mkDefault true;
      };
    };
  };
}
