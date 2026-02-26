{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "yazi";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "TUI file manager";
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
