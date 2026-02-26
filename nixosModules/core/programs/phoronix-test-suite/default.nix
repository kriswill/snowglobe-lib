{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "phoronix-test-suite";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "massive benchmarking suite for hardware diagnostics and performance";
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
