{ config, lib, ... }:
let
  cfg = config.earthgman.printing-config;
in
{
  options.earthgman.printing-config.enable = lib.mkEnableOption "EarthGman's CUPS printing configuration";
  config = lib.mkIf cfg.enable {
    services = {
      avahi = {
        enable = lib.mkDefault true;
        nssmdns4 = lib.mkDefault true;
        openFirewall = lib.mkDefault true;
      };
      printing = {
        enable = lib.mkDefault true;
        browsed.enable = lib.mkDefault false;
      };
    };
  };
}
