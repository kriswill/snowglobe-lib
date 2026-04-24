{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "syncthingtray";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "tray applet for syncthing";
    programName = programName;
    packageName = "syncthingtray-minimal";
    extraOptions = {
      systemd.enable = lib.mkEnableOption "syncthingtray as a systemd user service";
    };
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.syncthingtray = lib.mkIf (cfg.systemd.enable) (
          slib.mkGraphicalService {
            serviceName = "syncthingtray";
            programArgs = [ "--wait" ];
            package = cfg.package;
          }
          // {
            wantedBy = [ "syncthing.service" ];
          }
        );
      };
    }
  );
}
