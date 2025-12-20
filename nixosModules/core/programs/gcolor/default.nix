{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "gcolor";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    description = "a color wheel and picker written in gtk";
    programName = program-name;
    packageName = "gcolor3";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
