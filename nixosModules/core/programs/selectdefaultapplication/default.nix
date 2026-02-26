{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "selectdefaultapplication";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "frontend for managing the xdg mime types database";
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
