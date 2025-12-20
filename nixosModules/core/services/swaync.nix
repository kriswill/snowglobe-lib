{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.swaync;
in
{
  options.services.swaync = {
    enable = lib.mkEnableOption "the sway notification center service";

    package = lib.mkPackageOption pkgs "swaynotificationcenter" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.user = {
      services.swaync = {
        path = [ cfg.package ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${cfg.package}/bin/swaync";
          Restart = "on-failure";
          RestartSec = 5;
        };
        unitConfig = {
          After = "graphical-session.target";
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Description = "swaync-daemon";
          PartOf = "graphical-session.target";
        };
      };
    };
  };
}
