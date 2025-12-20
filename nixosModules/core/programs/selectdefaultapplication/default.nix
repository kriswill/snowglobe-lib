{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "selectdefaultapplication";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "Simple QT app for setting default applications for xdg mimetypes";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
