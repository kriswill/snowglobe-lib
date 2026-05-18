{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "batsignal";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "simple battery monitor written in C";
    programName = programName;
    packageName = programName;
    extraOptions = {
      systemd = {
        enable = lib.mkEnableOption "batsignal as a systemd service";
        programArgs = lib.mkOption {
          description = "Arguments Passed to batsignal";
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.batsignal = lib.mkIf (cfg.systemd.enable) (
          slib.mkGraphicalService {
            serviceName = "batsignal";
            package = cfg.package;
            extraServiceConfig = {
              Restart = "no";
            };
          }
        );
      };
    }
  );
}
