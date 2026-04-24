{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "networkmanagerapplet";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    inherit pkgs;
    description = "networkmanager applet";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
      extraModules = {
        # set XDG_DATA_DIRS to include pkgs.networkmanagerapplet/share
        # required for gnome's environment assumptions
        # if this is not set then icons will not render on window managers
        environment.profiles = [ "${cfg.package}" ];

        systemd.user.services.networkmanagerapplet = slib.mkGraphicalService {
          serviceName = "networkmanagerapplet";
          binName = "nm-applet";
          package = cfg.package;
        };
      };
    }
  );
}
