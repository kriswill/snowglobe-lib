{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "swayidle";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "idle daemon for wayland";
    programName = programName;
    packageName = programName;
    extraOptions = {
      systemd = {
        enable = lib.mkEnableOption "swayidle as a systemd service";
        programArgs = lib.mkOption {
          description = "arguments to swayidle as a service";
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.swayidle = lib.mkIf (cfg.systemd.enable) (
          lib.mkGraphicalService {
            serviceName = "swayidle";
            package = cfg.package;
            waylandDependent = true;
          }
        );
      };
    }
  );
}
