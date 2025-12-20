{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.kdeconnect-indicator;
in
{
  options.services.kdeconnect-indicator = {
    enable = lib.mkEnableOption "kdeconnect indicator daemon";

    package = lib.mkPackageOption pkgs.kdePackages "kdeconnect-kde" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.user = {
      services.kdeconnect-indicator = {
        path = [ cfg.package ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/kdeconnect-indicator";
          Restart = "on-failure";
          RestartSec = 5;
        };
        unitConfig = {
          After = "graphical-session.target";
          Description = "indiciator applet for kdeconnect";
          PartOf = "graphical-session.target";
        };
      };
    };
  };
}
