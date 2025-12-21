{ config, lib, ... }:
let
  cfg = config.gman.printing;
in
{
  options.gman.printing.enable = lib.mkEnableOption "gman's CUPS printing configuration";
  config = lib.mkIf cfg.enable {
    services = {
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
      printing = {
        enable = true;
        browsed.enable = lib.mkDefault false;
        tempDir = lib.mkDefault "/tmp/cups";
      };
    };
  };
}
