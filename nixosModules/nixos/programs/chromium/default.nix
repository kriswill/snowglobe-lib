{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "chromium";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    programName = programName;
    packageName = programName;
    excludedOptions = [ "enable" ];
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
