{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "kdeconnect";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "Multi platform app that allows your devices to communicate";
    programName = programName;
    packageName = programName;
    excludedOptions = [
      "enable"
      "package"
    ];
    extraOptions = {
      trayApplet.enable = lib.mkEnableOption "kdeconnect Indicator applet for desktop systrays";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.kdeconnect-indicator = lib.mkIf (cfg.trayApplet.enable) (
          lib.mkGraphicalService {
            serviceName = "kdeconnect-indicator";
            package = cfg.package;
          }
        );
      };
    }
  );
}
