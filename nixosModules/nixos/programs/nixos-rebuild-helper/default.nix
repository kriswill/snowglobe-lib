{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "nixos-rebuild-helper";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    description = "Helper script to sync your nixos generations with git. Also integrates with NOM.";
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
