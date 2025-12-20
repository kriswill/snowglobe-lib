{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.gman.pipewire;
in
{
  options.gman.pipewire.enable = lib.mkEnableOption "gman's pipewire configuration";
  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true; # hands out realtime scheduling priority to user processes on demand. Improves performance of pulse

    services = {
      pipewire = {
        # enables alsa, pulseaudio, and jack support by default
        enable = true;
        alsa.enable = lib.mkDefault true;
        alsa.support32Bit = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
        jack.enable = lib.mkDefault true;
      };
    };
  };
}
