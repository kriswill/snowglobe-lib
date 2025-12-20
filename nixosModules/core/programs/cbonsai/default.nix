{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "cbonsai";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a program to grow randomly generated bonsai trees in your terminal";
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
