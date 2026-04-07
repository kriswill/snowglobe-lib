{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "snowglobe-rebuild";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    inherit pkgs;
    description = "wrapper for nixos-rebuild ensuring that your system updates are synced with git";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
