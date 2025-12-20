{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "discover";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "the KDE frontent to flatpak";
    programName = program-name;
    packageName = program-name;
    pkgs = pkgs.kdePackages;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
