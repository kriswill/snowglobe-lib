{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "retroarch";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "collection of emulators for retro games";
    programName = program-name;
    packageName = "retroarch-free";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
