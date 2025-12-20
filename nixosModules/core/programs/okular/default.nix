{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "okular";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "pdf viewer from KDE Plasma";
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
