{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "waybar";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "Highly configurable status bar for wayland written in GTK";
    programName = programName;
    packageName = programName;
    extraOptions = {
      systemd.enable = lib.mkEnableOption "the systemd unit for waybar";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.waybar = lib.mkIf cfg.systemd.enable (
          lib.mkGraphicalService {
            serviceName = "waybar";
            package = cfg.package;
            waylandDependent = true;
          }
        );
      };
    }
  );
}
