{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "nautilus";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "the file manager from Gnome DE";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    # enable the virtual FS for mounting network drives
    services.gvfs.enable = true;
  };
}
