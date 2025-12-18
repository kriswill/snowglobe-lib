{ config, lib, ... }:
let
  cfg = config.gman.bluetooth;
in
{
  options.gman.bluetooth.enable = lib.mkEnableOption "gman's bluetooth configuration";
  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = lib.mkDefault true;
    # TODO research hsphfpd
  };
}
