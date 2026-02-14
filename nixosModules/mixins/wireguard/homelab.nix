{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.gman.wireguard.homelab;
in
{
  options.gman.wireguard.homelab.enable = mkEnableOption "gmans wireguard vpn";
  config = mkIf cfg.enable {
    sops.secrets.homelab_wg_conf.path = "/etc/wireguard/homelab.conf";
    networking = {
      # staticaly map included workstations and peers as they are not always going to be in the DNS server.
      extraHosts = ''
        10.0.25.2 cypher
        10.0.25.3 think-one 
        10.0.25.5 pixel-6a 
      '';

      # use a nonstandard port so the interface can always be up even if another wireguard tunnel is in use.
      firewall.allowedUDPPorts = [ 51821 ];
      # set resolvconf to timeout the default dns server "10.0.25.1" after 1 second
      # This allows dns requests to complete using fallback servers such as the one configured by DHCP if the wireguard server went down
      resolvconf.extraOptions = [ "timeout:1" ];

      # restart on network reconnect
      networkmanager = {
        dispatcherScripts = [
          {
            # work around a weird issue where the endpoint will no longer resolve after a host leaves the local home network.
            source = pkgs.writeText "wireguard-hook" ''
              if [ "$2" = "connectivity-change" ]; then
                systemctl restart wg-quick-homelab
              fi
            '';
          }
        ];
        # make the wireguard server the default DNS resolver for easy hostname access to homelab
        insertNameservers = [ "10.0.25.1" ];
      };

      wg-quick.interfaces = {
        homelab = {
          autostart = true;
          configFile = config.sops.secrets.homelab_wg_conf.path; # store whole file in secrets
        };
      };
    };
  };
}
