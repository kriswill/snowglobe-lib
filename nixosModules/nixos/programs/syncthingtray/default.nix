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
        systemd.user.services.syncthingtray = lib.mkIf (cfg.systemd.enable) (
          lib.mkGraphicalService {
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
