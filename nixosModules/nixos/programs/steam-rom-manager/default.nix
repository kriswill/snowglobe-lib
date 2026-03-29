{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "steam-rom-manager";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "manage your steam game metadata and artwork";
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
