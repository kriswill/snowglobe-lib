{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "waybar";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "Highly configurable status bar for wayland written in GTK";
    programName = programName;
    packageName = programName;
    extraOptions = {
      systemd.enable = lib.mkEnableOption "the systemd unit for waybar";
    };
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        systemd.user.services.waybar = lib.mkIf cfg.systemd.enable (
          slib.mkGraphicalService {
            serviceName = "waybar";
            package = cfg.package;
            waylandDependent = true;
          }
        );
      };
    }
  );
}
