{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "syncthingtray";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "tray applet for syncthing";
    programName = programName;
    packageName = "syncthingtray-minimal";
    extraOptions = {
      systemd.enable = lib.mkEnableOption "syncthingtray as a systemd user service";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.syncthingtray = lib.mkIf (cfg.systemd.enable) {
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
            Requisite = [
              "syncthing.service"
              "graphical-session.target"
            ];
            After = "graphical-session.target";
            Description = "syncthing tray";
            PartOf = "graphical-session.target";
          };
        };
      };
    }
  );
}
