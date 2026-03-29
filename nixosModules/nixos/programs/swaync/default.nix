{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "swaync";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "wayland notification daemon";
    programName = programName;
    packageName = "swaynotificationcenter";
    extraOptions = {
      systemd.enable = lib.mkEnableOption ''
        Swaync as a systemd user unit.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.swaync = lib.mkIf (cfg.systemd.enable) (
          lib.mkGraphicalService {
            serviceName = "swaync";
            package = cfg.package;
            waylandDependent = true;
            extraDescription = "-daemon";
          }
        );
      };
    }
  );
}
