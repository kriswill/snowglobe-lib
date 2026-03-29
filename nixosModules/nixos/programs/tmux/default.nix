{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "tmux";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "terminal multiplexer";
    programName = programName;
    packageName = programName;
    excludedOptions = [
      "enable"
      "package"
    ];
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
