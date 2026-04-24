{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.snowglobe-lib.pipewire-config;
  slib = import ../../lib/functions/module-wrappers { inherit lib; };
in
{
  options.snowglobe-lib.pipewire-config.enable = lib.mkEnableOption "Snowglobe-Lib's pipewire configuration";
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
