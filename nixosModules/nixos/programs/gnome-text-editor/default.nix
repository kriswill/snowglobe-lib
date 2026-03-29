{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "gnome-text-editor";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "text editor / notepad from the GNOME desktop environment";
    programName = programName;
    packageName = programName;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
