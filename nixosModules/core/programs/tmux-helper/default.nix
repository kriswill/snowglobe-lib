{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "tmux-helper";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "Helper script for creating and managing tmux sessions";
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
