{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "obsidian";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "feature rich note taking app";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
