{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "pwvucontrol";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "pipwire-pulse volume control tool written in gtk";
    programName = program-name;
    packageName = program-name;
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
