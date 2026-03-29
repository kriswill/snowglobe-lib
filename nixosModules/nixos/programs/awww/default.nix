{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "awww";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "answer to your wayland wallpaper woes";
    programName = programName;
    packageName = programName;
    extraOptions = {
      systemd = {
        enable = lib.mkEnableOption ''
          awww-daemon as a systemd user service
        '';
        programArgs = lib.mkOption {
          description = "arguments to the awww-daemon service";
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
        systemd.user.services.awww-daemon = lib.mkIf (cfg.systemd.enable) (
          lib.mkGraphicalService {
            serviceName = "awww-daemon";
            package = cfg.package;
            waylandDependent = true;
          }
        );
      };
    }
  );
}
