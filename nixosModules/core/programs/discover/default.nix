{
  pkgs,
  lib,
  config,
  ...
}:
let
  programName = "discover";
  cfg = config.programs.${programName};
in
{
  options.programs.${programName} = lib.mkProgramOption {
    pkgs = pkgs.kdePackages;
    description = "KDE frontend to flatpak";
    programName = programName;
    packageName = programName;
  };

  config = lib.mkIf cfg.enable (
    lib.installProgram {
      inherit programName config;
    }
  );
}
