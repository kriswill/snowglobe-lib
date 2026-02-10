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

    systemd.user.services.syncthingtray = {
      path = [ cfg.package ];
      wants = [
        "syncthing.service"
      ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "exec";
        # required to wait for a tray to bind to
        ExecStart = "${cfg.package}/bin/syncthingtray --wait";
        Restart = "on-failure";
        ExitType = "cgroup";
        RestartSec = 5;
        Slice = "app.slice";
      };
      unitConfig = {
        Requires = "syncthing.service";
        After = "graphical-session.target";
        Description = "syncthing tray";
        PartOf = "graphical-session.target";
      };
    };
  };
}
