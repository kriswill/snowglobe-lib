{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "gcolor";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "color picker written in gtk";
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
