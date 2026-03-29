{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "nix-fast-build";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "the power of nix-eval-jobs with nix-output-monitor to speed-up your evaluation and building process";
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
