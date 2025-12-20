{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.awww;
in
{
  options.services.awww = {
    enable = lib.mkEnableOption "the awww-daemon";

    package = lib.mkPackageOption pkgs "awww" { };

    flags = lib.mkOption {
      description = "extra flags passed to the start of awww-daemon";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.user = {
      services.awww-daemon = {
        path = [ cfg.package ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart =
            "${cfg.package}/bin/awww-daemon"
            + lib.optionalString (cfg.flags != [ ]) (" " + (lib.concatStringsSep " " cfg.flags));
          Restart = "on-failure";
          RestartSec = 5;
        };
        unitConfig = {
          After = "graphical-session.target";
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Description = "awww-daemon";
          PartOf = "graphical-session.target";
        };
      };
    };
  };
}
