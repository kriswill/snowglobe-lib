{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "zint";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "studio for barcoding";
    programName = programName;
    packageName = "zint-qt";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
