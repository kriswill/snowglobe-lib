{
  pkgs,
  lib,
  config,
  ...
}:
let
  slib = import ../../../../lib/functions/module-wrappers { inherit lib; };
  programName = "nix-fast-build";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = slib.mkProgramOption {
    description = "the power of nix-eval-jobs with nix-output-monitor to speed-up your evaluation and building process";
    programName = programName;
    packageName = programName;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    slib.installProgram {
      inherit programName config;
    }
  );
}
