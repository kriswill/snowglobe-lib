{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "lutris";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a game management tool for linux";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.wine
      pkgs.wine64
    ];
  };
}
