{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.gman.wireguard.main;
in
{
  options.gman.wireguard.main.enable = mkEnableOption "gmans wireguard vpn";
  config = mkIf cfg.enable {
    sops.secrets.wg1_conf.path = "/etc/wireguard/wg1.conf";
    networking = {
      firewall.allowedUDPPorts = [ 51821 ];

      # restart on network reconnect
      networkmanager.dispatcherScripts = [
        {
          source = pkgs.writeText "wireguard-hook" ''
            if [[ "$1" == "wg"* || "$1" == "virbr"* ]]; then
              exit 0
            fi

            if [ "$2" == "up" ]; then
              systemctl restart wg-quick-wg1
            fi
          '';
        }
      ];

      wg-quick.interfaces = {
        wg1 = {
          autostart = lib.mkDefault false;
          configFile = config.sops.secrets.wg1_conf.path; # store whole file in secrets
        };
      };
    };
  };
}
