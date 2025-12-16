# I think the default syncthing service from services.syncthing is mostly broken as a user level unit
# declarative configuration does not work and it will not autostart the service.

# so I wrote this hack module so I can run syncthing as a specific user
# all configuration will be done through the web ui or stored dotfiles
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.syncthing-user;
in
{
  options.gman.syncthing-user = {
    enable = lib.mkEnableOption "gman's user-level syncthing configuration";
    # syncthing binds to ports which means only 1 instance can be running on a machine at 1 time
    # so restrict syncthing to running as 1 user only
    config = {
      user = lib.mkOption {
        description = "The user that will run syncthing";
        type = lib.types.str;
        # not really useful but it needed to be set to something by default
        default = "syncthing";
      };

      package = lib.mkPackageOption pkgs "syncthing" { };

      openDefaultPorts = lib.mkOption {
        description = "Whether to open the default ports in the firewall: TCP/UDP 22000 for transfers and UDP 21027 for discovery.";
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ cfg.config.package ];
        services.syncthingtray.enable = lib.mkDefault (config.meta.desktop != "");

        systemd.user = {
          services.syncthing = {
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${cfg.config.package}/bin/syncthing serve --no-browser --no-restart";
              Restart = "on-failure";
              RestartSec = 5;
            };
            unitConfig = {
              ConditionUser = cfg.config.user;
              After = "default.target";
              Description = "per-user syncthing service";
              PartOf = "default.target";
            };
          };
        };
      }
      (lib.mkIf cfg.config.openDefaultPorts {
        networking.firewall = {
          allowedTCPPorts = [ 22000 ];
          allowedUDPPorts = [
            22000
            21027
          ];
        };
      })
    ]
  );
}
