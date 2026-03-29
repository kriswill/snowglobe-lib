{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "manga-tui";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "program to read mango from your terminal";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
