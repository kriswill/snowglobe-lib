{ config, lib, ... }:
let
  cfg = config.gman.printing;
in
{
  options.gman.printing.enable = lib.mkEnableOption "gman's CUPS printing configuration (printers not included)";
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
      };
    };
    # TODO see if I can remove this
    networking.firewall.allowedUDPPorts = [ 5353 ];
  };
}
