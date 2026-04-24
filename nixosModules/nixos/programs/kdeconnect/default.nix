{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "kdeconnect";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
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
    slib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.kdeconnect-indicator = lib.mkIf (cfg.trayApplet.enable) (
          slib.mkGraphicalService {
            serviceName = "kdeconnect-indicator";
            package = cfg.package;
          }
        );
      };
    }
  );
}
