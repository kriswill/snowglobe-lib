{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.kanshi;
in
{
  options.services.kanshi = {
    enable = lib.mkEnableOption "kanshi daemon";

    package = lib.mkPackageOption pkgs "kanshi" { };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ cfg.package ];
    };

    systemd.user = {
      services.kanshi = {
        path = [ cfg.package ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/kanshi";
        };
        unitConfig = {
          After = "graphical-session.target";
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Description = "kanshi daemon";
          PartOf = "graphical-session.target";
        };
      };
    };
  };
}
