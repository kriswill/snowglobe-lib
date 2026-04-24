{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "swaync";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
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
    slib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.swaync = lib.mkIf (cfg.systemd.enable) (
          slib.mkGraphicalService {
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
