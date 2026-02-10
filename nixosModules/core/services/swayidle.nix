{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.swayidle;
in
{
  options.services.swayidle = {
    enable = lib.mkEnableOption "idle daemon from sway";
    flags = lib.mkOption {
      description = "extra flags passed to swayidle";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    package = lib.mkPackageOption pkgs "swayidle" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.user = {
      services.swayidle = {
        # allow configuration file to execute programs installed through nixpkgs
        path = [
          cfg.package
          "/run/current-system/sw"
        ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "exec";
          ExecStart =
            "${cfg.package}/bin/swayidle "
            + lib.optionalString (cfg.flags != [ ]) (lib.concatStringsSep " " cfg.flags);
          Restart = "on-failure";
          RestartSec = 5;
          Slice = "app.slice";
        };
        unitConfig = {
          After = "graphical-session.target";
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Description = "swayidle";
          PartOf = "graphical-session.target";
        };
      };
    };
  };
}
