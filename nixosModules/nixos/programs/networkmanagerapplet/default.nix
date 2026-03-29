{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "networkmanagerapplet";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "networkmanager applet";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
      extraModules = {
        # set XDG_DATA_DIRS to include pkgs.networkmanagerapplet/share
        # required for gnome's environment assumptions
        # if this is not set then icons will not render on window managers
        environment.profiles = [ "${cfg.package}" ];

        systemd.user.services.networkmanagerapplet = lib.mkGraphicalService {
          serviceName = "networkmanagerapplet";
          binName = "nm-applet";
          package = cfg.package;
        };
      };
    }
  );
}
