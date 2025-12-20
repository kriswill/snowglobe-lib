{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "nwg-look";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "gtk configuration utility for wlr-roots based wayland manager";
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
