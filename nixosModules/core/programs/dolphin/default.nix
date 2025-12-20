{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "dolphin";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "the filemanager from KDE";
    programName = program-name;
    packageName = program-name;
    pkgs = pkgs.kdePackages;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.kdePackages.qtsvg
      pkgs.kdePackages.kio-fuse
      pkgs.kdePackages.kio-extras
    ];
  };
}
