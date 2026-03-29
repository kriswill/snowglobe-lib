{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "kanshi";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "Display configuration for wayland compositors that supports configurable profiles";
    programName = programName;
    packageName = programName;
    extraOptions = {
      systemd.enable = lib.mkEnableOption "Kanshi as a systemd user service";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.kanshi = lib.mkIf (cfg.systemd.enable) (
          lib.mkGraphicalService {
            serviceName = "kanshi";
            package = cfg.package;
            waylandDependent = true;
          }
        );
      };
    }
  );
}
