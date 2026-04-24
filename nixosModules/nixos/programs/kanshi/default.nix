{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "kanshi";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "Display configuration for wayland compositors that supports configurable profiles";
    programName = programName;
    packageName = programName;
    extraOptions = {
      systemd.enable = lib.mkEnableOption "Kanshi as a systemd user service";
    };
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.kanshi = lib.mkIf (cfg.systemd.enable) (
          slib.mkGraphicalService {
            serviceName = "kanshi";
            package = cfg.package;
            waylandDependent = true;
          }
        );
      };
    }
  );
}
