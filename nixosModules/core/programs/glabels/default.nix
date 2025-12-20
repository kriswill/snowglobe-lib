{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "glabels";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "open source label maker for personal use or small businesses";
    programName = program-name;
    packageName = "glabels-qt";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
