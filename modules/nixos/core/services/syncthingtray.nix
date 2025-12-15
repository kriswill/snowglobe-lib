{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.syncthingtray;
in
{
  options.services.syncthingtray = {
    enable = lib.mkEnableOption "syncthing tray daemon";

    package = lib.mkPackageOption pkgs "syncthingtray" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.user = {
      services.syncthingtray = {
        path = [ cfg.package ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          # require syncthing to wait for a tray to bind to
          ExecStart = "${cfg.package}/bin/syncthingtray --wait";
        };
        unitConfig = {
          After = "graphical-session.target";
          Description = "syncthing tray daemon";
          PartOf = "graphical-session.target";
        };
      };
    };
  };
}
