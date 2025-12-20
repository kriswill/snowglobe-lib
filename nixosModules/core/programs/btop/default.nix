{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "btop";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} = lib.mkProgramOption {
    programName = program-name;
    description = "better top";
    inherit pkgs;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
