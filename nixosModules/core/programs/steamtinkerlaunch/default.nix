{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "steamtinkerlaunch";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "Linux wrapper tool for use with the Steam client for custom launch options and 3rd party programs";
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
