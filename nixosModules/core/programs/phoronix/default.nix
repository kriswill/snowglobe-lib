{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "phoronix";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a test suite for benchmarking";
    programName = program-name;
    packageName = "phoronix-test-suite";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
